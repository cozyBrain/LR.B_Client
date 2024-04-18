## By default, link_creator won't connect already interconnected objs.
## Right click : Add start point of the link.
## Left click  : Connect target from the start points.
## 'R' press   : Reset added start points.
class_name client_player_module_link_creator
extends Node

@onready var quick_menu = %quick_menu
@onready var pointer := $"../pointer" as client_player_module_pointer
@onready var unified_chunk_observer = %player_modules/unified_chunk_observer as client_player_module_unified_chunk_observer
@onready var link_projection = %space_modules/link_projection as client_space_module_link_projection
@onready var console_window = %"3d_hud_projector"/console
@onready var console = $"../console"

var tool_name := &"link_creator"

# link parameters
var start_points: Array

var requested_tasks: Dictionary

func handle(v: Dictionary):
	var response = v.get("Response")
	match response:
		null:
			pass
		var task_id:
			# Clear the task.
			var task = instance_from_id(task_id)
			if task != null:
				unified_chunk_observer.unobserve_deferred(task)
				requested_tasks.erase(task)


func _ready():
	register_quick_menu_button()
	set_process_unhandled_input(false)
	# Connect console_window's typing signal to ignore input when player is typing.
	console_window.connect("typing_started", _on_console_typing_started)
	console_window.connect("typing_stopped", _on_console_typing_stopped)

func _on_console_typing_started():
	set_process_unhandled_input(false)
func _on_console_typing_stopped():
	if %player.selected_tool == self:
		set_process_unhandled_input(true)


func register_quick_menu_button():
	# create [node_creator] button in the "Design" category.
	var category = "Design"
	var new_button := Button.new()
	new_button.text = tool_name
	new_button.connect("pressed", _on_tool_selected)
	quick_menu.add_button(new_button, category, true)
	

func _on_tool_selected():
	%player.select_tool(self)
	set_process_unhandled_input(true)

func deselect():
	set_process_unhandled_input(false)


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			var pos = pointer.get_pointer_position()
			if typeof(pos) == TYPE_VECTOR3I and pointer.current_mode == pointer.Mode.VoxelPointer:
				if event.button_index == MOUSE_BUTTON_LEFT:
					# Connect to the obj(pos) from the start_points.
					if start_points.is_empty():
						console.print_line(["No start points selected."])
					else:
						# Create task to observe target_chunk.
						var task := client_player_module_unified_chunk_observer.observing_task.new()
						# Register the task to clear the task later.
						requested_tasks[task] = true
						var links_to_create := []
						for point in start_points:
							var link = load("res://session/virtual_remote_hub/space/objects/shapes/triLink/area(visible).tscn").instantiate()
							@warning_ignore("static_called_on_instance")
							var aligned_link = align_link(point, pos, link)
							link_projection.add_child(aligned_link) # Visualize link.
							@warning_ignore("static_called_on_instance")
							var calculated_chunkPosForLinkPointer = calculateChunkPosForLinkPointer(point, pos, 0.5)
							# Add chunks_to_observe. (The task ignores duplication.)
							task.add_chunk_to_observe([calculated_chunkPosForLinkPointer[0]]) # chunk pos for link pointer.
							task.add_chunk_to_observe([calculated_chunkPosForLinkPointer[1]]) # start_point chunk pos.
							task.add_chunk_to_observe([calculated_chunkPosForLinkPointer[2]]) # end_point chunk pos.
							var link_data: Array[Vector3i] = [point] # start_point
							link_data.append_array(calculated_chunkPosForLinkPointer[0])
							link_data.append(pos) # end_point
							link_data.append(0) # Add channel data.
							links_to_create.append(link_data)
						unified_chunk_observer.observe(task)
						# Wait until the chunk is guaranteed to be accessible.
						await task.done
						# Create links.
						terminal.handle(
							{
								"Hub": 				terminal.virtual_remote_hub,
								"ModuleContainer": 	"Player",
								"Module": 			tool_name,
								"Content": {
									"Request": 		"create",
									"TaskID":		task.get_instance_id(),
									"links":		links_to_create,
								},
							}
						)
						
				elif event.button_index == MOUSE_BUTTON_RIGHT: ##TODO: Visualize selected start_points.
					# Add point as start point of the link.
					# Append the point until player reset. (reset button is 'R' by default.)
					start_points.append(pos) ##TODO: Prevent point duplication.
					print("Added a start_point: ", pos)
					print("start_points: ", start_points)
	
	if Input.is_action_just_pressed("reset"):
		# Reset start_points.
		print("R pressed!")
		start_points.clear()


## Set link position and rotation with A and B.
## A(start_point), B(end_point).
static func align_link(A: Vector3, B: Vector3, link: Object) -> Object:
	#var link := node.areas[&"triLink"] as Node3D
	# Config link.
	var distance = A.distance_to(B)
	var position = (A + B) / 2
	# Set link length.
	link.scale.z = link.scale.z * distance
	# Set link direction
	var direction = A.direction_to(B)
	var d = Vector3.UP
	if abs(d.dot(direction)) > 0.99:
		d = Vector3.RIGHT
	link.look_at_from_position(position, position + direction, d)
	return link


#Dictionary[link_id] = Dictionary[link_id] + 1

## start and end_point shouldn't be chunk pos.
static func calculateChunkPosForLinkPointer(start_point: Vector3, end_point: Vector3, distance_threshold) -> Array:
	var distance = start_point.distance_to(end_point)
	var link_pointer_count = max(2, int(distance / distance_threshold))
	var start_point_chunk := Chunk.global_pos_to_chunk_pos(start_point, client_space_module_chunk_projection.chunk_size)
	var end_point_chunk := Chunk.global_pos_to_chunk_pos(end_point, client_space_module_chunk_projection.chunk_size)
	var chunk_pos_list: Array[Vector3i] = []
	
	for i in range(1, link_pointer_count):
		var t = float(i) / (link_pointer_count - 1)
		var link_pointer_chunk_pos = Chunk.global_pos_to_chunk_pos(start_point.lerp(end_point, t), client_space_module_chunk_projection.chunk_size)
		# Exclude start_point_chunk and end_point_chunk position.
		if link_pointer_chunk_pos == start_point_chunk or link_pointer_chunk_pos == end_point_chunk:
			continue
		# Prevent duplication
		if not chunk_pos_list.is_empty():
			if chunk_pos_list.back() == link_pointer_chunk_pos:
				continue
		chunk_pos_list.append(link_pointer_chunk_pos)
	
	return [chunk_pos_list, start_point_chunk, end_point_chunk]
