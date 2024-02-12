extends Node

func _on_chunk_observed(chunk: Chunk.chunk_item):
	terminal.handle(
		{
			"Hub" : terminal.local_hub,
			"ModuleContainer" : "Player",
			"Module" : "unified_chunk_observer",
			"Content" : {
				"Request": 			"observe_chunk",
				"observed_chunks":	[chunk.chunk_pos],
			}
		}
	)
