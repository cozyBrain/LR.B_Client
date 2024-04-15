extends Area3D

func set_collision_layer_and_mask_to_detect_chunks():
	$Area3D.collision_layer = 0
	$Area3D.collision_mask = client_space_module_chunk_projection.CHUNK_LAYER
