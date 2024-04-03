extends Node3D

func set_collision_layer_and_mask_to_chunk_layer():
	$Area3D.collision_layer = client_space_module_chunk_projection.CHUNK_LAYER
	$Area3D.collision_mask = client_space_module_chunk_projection.CHUNK_LAYER
