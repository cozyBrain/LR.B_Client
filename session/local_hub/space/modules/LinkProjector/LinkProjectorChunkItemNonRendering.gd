class_name LinkProjectorChunkItemNonRendering extends LinkProjectorChunkItem

# Overrides to skip unnecessary functionality from the parent class.
func _init():
	pass
func _ready():
	pass

## if there's no link, return true to be freed.
func decrement_link_observation_count(link_id: Array) -> bool:
	links[link_id] -= 1
	if links[link_id] == 0:
		return erase_link(link_id)
	return false

func increment_link_observation_count(link_id: Array):
	if not links.has(link_id):
		links[link_id] = 1
	else:
		links[link_id] += 1

## if there's no link, return true to be freed.
func erase_link(link_id: Array) -> bool:
	if links.has(link_id):
		links.erase(link_id)
		return links.is_empty()
	return false

