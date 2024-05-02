extends Area3D

func set_collision_layer_and_mask_to_detect_chunks():
	$Area3D.collision_layer = 0
	$Area3D.collision_mask = SpaceChunkProjector.CHUNK_LAYER
