extends Node3D

func set_collision_layer_and_mask_to_detect_chunks():
	$Area3D.collision_layer = 0
	$Area3D.collision_mask = client_space_module_chunk_projection.CHUNK_LAYER

func get_overlapping_chunks() -> Array[Vector3i]:
	var chunks := $Area3D.get_overlapping_areas() as Array[Area3D]
	print("whut..:", chunks)
	var chunk_coordinates: Array[Vector3i] = []
	for chunk in chunks:
		chunk_coordinates.append(chunk.position)
	return chunk_coordinates


#func _on_area_3d_area_entered(area):
	#print(area.global_position)
	#pass # Replace with function body.
