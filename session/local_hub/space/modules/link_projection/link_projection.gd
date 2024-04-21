class_name client_space_module_link_projection
extends Node3D

const module_name = &"link_projection"


static var chunk_size = Chunk.chunk_size ##TODO: Update
## link specific chunk. record rendered link.
var chunk: Dictionary = {}


# projection[start_point, end_point, channel] -> rendered_link[start_point, end_point] = {channel_1: link_data_a, channel_2: link_data_b}
func project(projection: Dictionary):
	for proj in projection.values():
		var start_point = proj[0]
		var start_point_chunk_pos = Chunk.global_pos_to_chunk_pos(start_point, Chunk.chunk_size)
		var start_point_chunk = chunk.get(start_point_chunk_pos) # link is rendered in this chunk.
		var end_point = proj[1]
		var channel = proj[2]
		var link_id = [start_point, end_point]
		if start_point_chunk == null:
			chunk[start_point_chunk_pos] = {link_id: {}} # Create start_point_chunk
			start_point_chunk = chunk[start_point_chunk_pos] # Update var, start_point_chunk.
		
		var link_channels: Dictionary = start_point_chunk.get(link_id)
		if link_channels == null:
			link_channels = {channel: false} # Channel data instead of 'false' if required.
			start_point_chunk[link_id] = link_channels
			# Render the connection.
			# Access self.chunk.
			
		# if the connection is already rendered.
		# Add channel.
		link_channels[channel] = false # link_data instead of 'false' if required.
