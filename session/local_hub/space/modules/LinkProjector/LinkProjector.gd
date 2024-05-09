class_name SpaceLinkProjector
extends Node3D

const module_name = &"LinkProjector"


static var chunk_size = R_SpaceChunk.chunk_size ##TODO: Update
## link specific chunk. record rendered link.
var chunk: Dictionary = {}
var link_chunk_item = preload("res://session/local_hub/space/modules/LinkProjector/LinkProjectorChunkItem.tscn")


# projection[start_point, end_point] -> link_id[start_point, end_point]
# chunk[start_point_chunk_pos] = link_chunk_item
# link_chunk_item.links[link_id] = link_observation_count
## Find start_point_chunk and request it to render links.
func project(projection: Dictionary):
	for link_id in projection.keys():
		print("LinkProjector.received link_id: ", link_id)
		##TODO: Consider unobserving link_pointers. Should link_chunk_item share links with chunk_item?? 
		var start_point = link_id[0]
		var start_point_chunk_pos = R_SpaceChunk.global_pos_to_chunk_pos(start_point, R_SpaceChunk.chunk_size)
		var start_point_chunk := chunk.get(start_point_chunk_pos) as LinkProjectorChunkItem # link is rendered in this chunk.
		var end_point = link_id[1]
		if start_point_chunk == null:
			chunk[start_point_chunk_pos] = link_chunk_item.instantiate() # Create start_point_chunk.
			start_point_chunk = chunk[start_point_chunk_pos] # Update var, start_point_chunk.
		
		# if projection[link_id] is null, this means that the link has been removed. This should be reflected.
		if projection[link_id] == null:
			start_point_chunk.erase_link(link_id)
			return
		
		add_child(start_point_chunk)
		start_point_chunk.increment_link_observation_count(link_id)


## start and end_point shouldn't be chunk pos.
static func calculateChunkPosForLinkPointer(start_point: Vector3, end_point: Vector3, distance_threshold) -> Array:
	var distance = start_point.distance_to(end_point)
	var link_pointer_count = max(2, int(distance / distance_threshold))
	var start_point_chunk := R_SpaceChunk.global_pos_to_chunk_pos(start_point, SpaceChunkProjector.chunk_size)
	var end_point_chunk := R_SpaceChunk.global_pos_to_chunk_pos(end_point, SpaceChunkProjector.chunk_size)
	var chunk_pos_list: Array[Vector3i] = []
	
	for i in range(1, link_pointer_count):
		var t = float(i) / (link_pointer_count - 1)
		var link_pointer_chunk_pos = R_SpaceChunk.global_pos_to_chunk_pos(start_point.lerp(end_point, t), SpaceChunkProjector.chunk_size)
		# Exclude start_point_chunk and end_point_chunk position.
		if link_pointer_chunk_pos == start_point_chunk or link_pointer_chunk_pos == end_point_chunk:
			continue
		# Prevent duplication
		if not chunk_pos_list.is_empty():
			if chunk_pos_list.back() == link_pointer_chunk_pos:
				continue
		chunk_pos_list.append(link_pointer_chunk_pos)
	
	return [chunk_pos_list, start_point_chunk, end_point_chunk]

## Set link position and rotation with A and B.
## A(start_point), B(end_point).
static func align_link(A: Vector3, B: Vector3, link: Object) -> Object:
	#var link := node.areas[&"triLink"] as Node3D
	# Config link.
	var distance = A.distance_to(B)
	var pos = (A + B) / 2
	# Set link length.
	link.scale.z = link.scale.z * distance
	# Set link direction
	var direction = A.direction_to(B)
	var d = Vector3.UP
	if abs(d.dot(direction)) > 0.99:
		d = Vector3.RIGHT
	link.look_at_from_position(pos, pos + direction, d)
	return link

static func align_link_and_get_transform(A: Vector3, B: Vector3) -> Transform3D:
	var distance = A.distance_to(B)
	var pos = (A + B) / 2
	var direction = (B - A).normalized()
	var length_scale = Vector3(1, 1, distance)
	
	var up = Vector3.UP
	if abs(up.dot(direction)) > 0.99:
		up = Vector3.RIGHT
	
	var z_axis = direction
	var x_axis = up.cross(z_axis).normalized()
	var y_axis = z_axis.cross(x_axis)
	
	var b = Basis(x_axis, y_axis, z_axis)
	var trans = Transform3D(b, pos).scaled(length_scale)
	
	return trans

