extends Node

@onready var space_module_chunk := %space_modules/Chunk as R_SpaceChunk


func handle(C : Dictionary):
	C = C["Content"]
	# get request
	match C.get("Request"):
		"observe":
			var observer = get_node("../"+C.get("observing_module")) ##TODO: Make it safe.
			var observation_request: Array = C.get("observation_request")
			for req in observation_request:
				space_module_chunk.queue_observe_or_unobserve(req[0], req[1], observer)
		"command_observe":
			var observer = C.get("observing_command")
			var chunk_pos: Vector3i = C.get("pos")
			space_module_chunk.observe(chunk_pos, observer)
		"command_unobserve":
			var observer = C.get("observing_command")
			var chunk_pos: Vector3i = C.get("pos")
			space_module_chunk.unobserve(chunk_pos, observer)

#func _on_chunk_observed(chunk: R_SpaceChunk.ChunkItem):
	#var chunk_pos: Vector3i = chunk.chunk_pos
	#terminal.handle(
		#{
			#"Hub" : terminal.local_hub,
			#"ModuleContainer" : "Space",
			#"Module" : "chunk_projection",
			#"Content" : {
				#"Request": 	"observe_chunk",
				#"pos": 		[chunk_pos.x, chunk_pos.y, chunk_pos.z],
				#"chunk": 	chunk.project_snapshot(),
			#}
		#}
	#)
# Update observed chunk.
#func _on_chunk_changes_observed(chunk: R_SpaceChunk.ChunkItem, changes: PackedByteArray):
	#var chunk_pos: Vector3i = chunk.chunk_pos
	#terminal.handle(
		#{
			#"Hub" : terminal.local_hub,
			#"ModuleContainer" : "Space",
			#"Module" : "chunk_projection",
			#"Content" : {
				#"Request": 	"observe_chunk",
				#"pos": 		[chunk_pos.x, chunk_pos.y, chunk_pos.z],
				#"chunk": 	changes,
			#}
		#}
	#)
