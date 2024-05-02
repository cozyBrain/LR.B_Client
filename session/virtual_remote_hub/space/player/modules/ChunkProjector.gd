class_name R_PlayerChunkProjector
extends Node
const module_name := &"ChunkProjector"

@onready var space_module_chunk := %space_modules/Chunk as R_SpaceChunk


func _on_chunk_observed(chunk: R_SpaceChunk.ChunkItem):
	var chunk_pos: Vector3i = chunk.chunk_pos
	terminal.handle(
		{
			"Hub" : terminal.local_hub,
			"ModuleContainer" : "Space",
			"Module" : module_name,
			"Content" : {
				"Request": 	"observe_chunk",
				"pos": 		[chunk_pos.x, chunk_pos.y, chunk_pos.z],
				"chunk": 	chunk.project_snapshot(),
			}
		}
	)
## Update observed chunk.
func _on_chunk_changes_observed(chunk: R_SpaceChunk.ChunkItem, changes: PackedByteArray):
	var chunk_pos: Vector3i = chunk.chunk_pos
	terminal.handle(
		{
			"Hub" : terminal.local_hub,
			"ModuleContainer" : "Space",
			"Module" : module_name,
			"Content" : {
				"Request": 	"observe_chunk",
				"pos": 		[chunk_pos.x, chunk_pos.y, chunk_pos.z],
				"chunk": 	changes,
			}
		}
	)

