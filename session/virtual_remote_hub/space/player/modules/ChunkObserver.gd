extends Node

@onready var space_module_chunk := %space_modules/Chunk as R_SpaceChunk


func handle(v : Dictionary):
	# get request
	match v.get("Request"):
		"observe":
			var observer = get_node("../"+v.get("observing_module")) ##TODO: Make it safe.
			var observation_request: Array = v.get("observation_request")
			for req in observation_request:
				space_module_chunk.queue_observe_or_unobserve(req[0], req[1], observer)


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
