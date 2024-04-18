class_name client_player_module_unified_chunk_observer
extends Node

## * If a player wants to use node_creator to create an obj in a chunk,
## where the player is not observing yet. and if the tool, node_creator
## only want to know if the chunk can be accessed, then the tool is going to
## observe(pos, "unified_chunk_observer", true). and the tool wait until unified_chunk_observer
## emit signal, observing_task.done.

## Server side unified_chunk_observer only sends what chunk is being observed.
## Client side module records it but if it records incorrectly and client's modules request something invalid operation,
## this may cause unexpected situation. In most cases, the operation is going to be ignored as remote_server.Chunk.get_chunk() will return null.


const module_name = &"unified_chunk_observer"

var observing_chunks: Dictionary
var tasks: Dictionary

@onready var chunk_observer = %player_modules/chunk_observer as client_player_module_chunk_observer

## When this module(observer) unobserve a chunk, chunk_observer call this function.
func _on_chunk_unobserved(pos: Vector3i):
	observing_chunks.erase(pos)


func handle(v: Dictionary):   
	match StringName(v.get("Request")):
		&"observe_chunk":
			var chunks = v.get("observed_chunks")
			for pos in chunks:
				observing_chunks[pos] = true
				for task in tasks:
					if (task as observing_task).prune(pos):
						tasks.erase(task)

class observing_task:
	signal done
	var chunks_to_observe: Dictionary 
	var observed_chunks: Array[Vector3i]
	func initial_prune(observing_chunks: Dictionary) -> bool: ## prune chunks_to_observe with observing_chunks.
		for pos in chunks_to_observe:
			if observing_chunks.has(pos):
				chunks_to_observe.erase(pos)
				observed_chunks.append(pos)
		if chunks_to_observe.is_empty():
			emit_signal("done")
			return true
		return false
	func prune(pos: Vector3i) -> bool:
		if chunks_to_observe.erase(pos):
			observed_chunks.append(pos)
			if chunks_to_observe.is_empty():
				# if chunks_to_observe is empty.
				emit_signal("done")
				return true
		return false
	func add_chunk_to_observe(pos: Array[Vector3i]):
		for p in pos:
			chunks_to_observe[p] = true


func observe(task: observing_task):
	call_deferred("_observe", task)

## This function must be called deferred because task.initial_prune() can emit the task.done signal.
## If not called deferred, this can block "await task.done" line.
func _observe(task: observing_task):
	for pos in task.chunks_to_observe.keys() as Array[Vector3i]:
		chunk_observer.observe(pos, self, chunk_observer.Accumulable)
	chunk_observer.flush_deferred()
	
	if task.initial_prune(observing_chunks):
		# if chunks_to_observe are already being observed by unified_chunk_observer.
		return
	# Register task.
	tasks[task] = true

func unobserve(task: observing_task):
	for pos in task.observed_chunks:
		# This may call _on_chunk_unobserved().
		chunk_observer.unobserve(pos, self, chunk_observer.Accumulable)
	chunk_observer.flush_deferred()

func unobserve_deferred(task: observing_task):
	call_deferred("unobserve", task)

