extends Node



func handle(v : Dictionary):
	# sync head rotation
	var head_rotation = v.get("sync_head_rotation")
	if head_rotation != null:
		%player/head.rotation.x = head_rotation[0]
		%player.rotation.y = head_rotation[1]
	# sync pos
	var pos = v.get("sync_position")
	if pos != null:
		%player.position = Vector3(pos[0], pos[1], pos[2])
