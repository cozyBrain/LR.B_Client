extends Node
class_name Chunk_projection

@onready var space_module_chunk := %space_modules/chunk as Chunk


func _on_chunk_observed(chunk: Chunk.chunk_item):
	var chunk_pos: Vector3i = chunk.chunk_pos
	terminal.handle(
		{
			"Hub" : terminal.local_hub,
			"ModuleContainer" : "Space",
			"Module" : "chunk_projection",
			"Content" : {
				"Request": 	"observe_chunk",
				"pos": 		[chunk_pos.x, chunk_pos.y, chunk_pos.z],
				"chunk": 	chunk.project_snapshot(),
			}
		}
	)
## Update observed chunk.
func _on_chunk_changes_observed(chunk: Chunk.chunk_item, changes: PackedByteArray):
	var chunk_pos: Vector3i = chunk.chunk_pos
	terminal.handle(
		{
			"Hub" : terminal.local_hub,
			"ModuleContainer" : "Space",
			"Module" : "chunk_projection",
			"Content" : {
				"Request": 	"observe_chunk",
				"pos": 		[chunk_pos.x, chunk_pos.y, chunk_pos.z],
				"chunk": 	changes,
			}
		}
	)

