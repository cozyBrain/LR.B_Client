class_name LinkProjectorChunkItemStrippedDown

var links := {}

## if there's no link, return true to be freed.
func unregister_link_pointer(link_id: Array):
	links.erase(link_id)

func register_link_pointer(link_id: Array):
	links[link_id] = true
