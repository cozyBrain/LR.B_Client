extends Node

const module_name := &"UnifiedChunkObserver"

func _on_chunk_observed(chunk: R_SpaceChunk.ChunkItem):
	terminal.handle(
		{
			"Hub" : terminal.local_hub,
			"ModuleContainer" : "Player",
			"Module" : module_name,
			"Content" : {
				"Request": 			"observe_chunk",
				"observed_chunks":	[chunk.chunk_pos],
			}
		}
	)
