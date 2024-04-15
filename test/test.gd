extends Node


func _ready():
	print("ready")
	print(calculate_intermediate_link_positions(Vector2(0, 0), Vector2(0, 8), 2))

static func calculate_intermediate_link_positions(node_a_position, node_b_position, distance_threshold):
	var distance = node_a_position.distance_to(node_b_position)
	var link_pointer_count = max(2, int(distance / distance_threshold))
	var pos_list := []
	pos_list.resize(link_pointer_count - 2)
	
	for i in range(1, link_pointer_count-1):
		var t = float(i) / (link_pointer_count - 1)
		var link_pointer_position = node_a_position.lerp(node_b_position, t)
		pos_list[i-1] = link_pointer_position
	return pos_list
