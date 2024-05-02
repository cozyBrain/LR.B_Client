class_name PlayerChunkObserver
extends Node

## Observers must have module_name(String or StringName).

const module_name = &"ChunkObserver"

var observation_map: Dictionary ## {chunk_pos: observers} observers is Dictionary.
var observation_request: Dictionary ## {"observer1": [[observe,pos],[unobserve,pos]], "observer2": [[observe,pos],...]}

const Accumulable = true

## If accumulable is true and you observe twice with the same observer; to unobserve the chunk completely, you have to unobserve it twice too.
## Accumulation is useful when multiple modules observe with a same observer. This reduces frequent observation requests.
## The observer.module_name means module path in the REMOTE_HUB.
func observe(chunk_pos: Vector3i, observer, accumulable: bool = true):
	if observation_map.has(chunk_pos):
		if observation_map[chunk_pos].has(observer):
			# Avoid duplicate request or accumulate if it's true.
			if accumulable: # Accumulate.
				observation_map[chunk_pos][observer] = observation_map[chunk_pos][observer] + 1
				return
		else:
			# When new observer observes the chunk.
			if accumulable: 
				# New <observer, accumulation>
				observation_map[chunk_pos][observer] = 1
				enqueue_new_request(observer, R_SpaceChunk.Observe, chunk_pos)
				return
			# New <observer>
			observation_map[chunk_pos][observer] = true
			# Enqueue new request.
			enqueue_new_request(observer, R_SpaceChunk.Observe, chunk_pos)
	else: 
		# When observer observes new chunk.
		if accumulable: 
			# New <chunk, observer, accumulation>
			observation_map[chunk_pos] = {observer: 1}
			enqueue_new_request(observer, R_SpaceChunk.Observe, chunk_pos)
			return
		# New <chunk, observer>
		observation_map[chunk_pos] = {observer: true}
		enqueue_new_request(observer, R_SpaceChunk.Observe, chunk_pos)

## If you unobserve(accumulable=false) chunk that is being observed with accumulation, the chunk will be unobserved at once.
func unobserve(chunk_pos: Vector3i, observer, accumulable: bool = true):
	if observation_map.has(chunk_pos):
		if accumulable:
			# Update accumulation (accumulation -= 1).
			observation_map[chunk_pos][observer] = observation_map[chunk_pos][observer] - 1
			if observation_map[chunk_pos][observer] >= 1: 
				# just pass, if there's accumulation.
				return 
			else: 
				# if there's no accumulation, erase.
				observation_map[chunk_pos].erase(observer)
				if observer.has_method("_on_chunk_unobserved"):
					observer._on_chunk_unobserved(chunk_pos)
		else:
			# if not accumulable.
			observation_map[chunk_pos].erase(observer)
			if observer.has_method("_on_chunk_unobserved"):
				observer._on_chunk_unobserved(chunk_pos)
		# Always check chunk if it has observers.
		if observation_map[chunk_pos].is_empty(): # if there's no observer, unobserve the chunk.
			# Unobserve.
			observation_map.erase(chunk_pos)
			enqueue_new_request(observer, R_SpaceChunk.Unobserve, chunk_pos)


func enqueue_new_request(observer, observation: int, chunk_pos: Vector3i):
	var observer_name: String = observer.module_name
	# Consolidate requests by observer_name.
	if not observation_request.has(observer_name):
		observation_request[observer_name] = []
	observation_request[observer_name].append([observation, chunk_pos])

## Send observation request.
func flush():
	for observer in observation_request.keys():
		terminal.handle(
			{
				"Hub" : terminal.virtual_remote_hub,
				"ModuleContainer" : "Player",
				"Module" : module_name,
				"Content" : {
					"Request": 	"observe",
					"observing_module": observer,
					"observation_request": observation_request[observer], 
				}
			}
		)
	observation_request.clear()

func flush_deferred():
	call_deferred("flush")
