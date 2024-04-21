class_name client_space_module_link_projection
extends Node3D

const module_name = &"link_projection"


static var chunk_size = Chunk.chunk_size ##TODO: Update
## link specific chunk. record rendered link.
var chunk: Dictionary = {}
@onready var link_chunk_item = preload("res://session/local_hub/space/modules/link_projection/link_chunk_item.tscn")


# projection[start_point, end_point, channel] -> link_id[start_point, end_point]
# chunk[start_point_chunk_pos] = link_chunk_item
# link_chunk_item.links[link_id] = {channel: channel_data}
func project(projection: Dictionary):
	for link_id in projection.keys():
		##TODO: Consider when projection[link_id] is null which means that the link is just removed.
		##TODO: Consider unobserving link_pointers. Should link_chunk_item share links with chunk_item?? 
		var start_point = link_id[0]
		var start_point_chunk_pos = Chunk.global_pos_to_chunk_pos(start_point, Chunk.chunk_size)
		var start_point_chunk = chunk.get(start_point_chunk_pos) # link is rendered in this chunk.
		var end_point = link_id[1]
		if start_point_chunk == null:
			chunk[start_point_chunk_pos] = link_chunk_item.new() # Create start_point_chunk
			start_point_chunk = chunk[start_point_chunk_pos] # Update var, start_point_chunk.
		
		if start_point_chunk.links.get(link_id) == null:
			start_point_chunk.links[link_id] = 1
			# Render the connection.
			# 
			pass
		else:
			start_point_chunk.links[link_id] += 1
