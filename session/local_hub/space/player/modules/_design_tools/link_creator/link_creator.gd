## By default, link_creator won't connect already interconnected objs.
## Right click : Add start point of the link.
## Left click  : Connect target from the start points.
## 'R' press   : Reset added start points.
extends Node

@onready var quick_menu = %quick_menu
@onready var pointer := $"../pointer" as client_player_module_pointer
@onready var unified_chunk_observer = %player_modules/unified_chunk_observer as client_player_module_unified_chunk_observer
@onready var link_projection = %space_modules/link_projection as client_space_module_link_projection
@onready var console_window = %"3d_hud_projector"/console


var tool_name := &"link_creator"

var requested_tasks: Dictionary

# link parameters
var start_points: Array


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
			var chunk_pos_to_observe: Vector3i = Chunk.global_pos_to_chunk_pos(pos, client_space_module_chunk_projection.chunk_size)
			if typeof(pos) == TYPE_VECTOR3I and pointer.current_mode == pointer.Mode.VoxelPointer:
				if event.button_index == MOUSE_BUTTON_LEFT:
					# Add point as end point of the link.
					
					pass
				elif event.button_index == MOUSE_BUTTON_RIGHT:
					# Add point as start point of the link.
					# Append the point until player reset. (reset button is 'R' by default.)
					start_points.append(pos)
					print(start_points)
	
	if Input.is_action_just_pressed("reset"):
		print("R pressed!")
		start_points.clear()



## A(start_point), B(end_point)
func foo(A: Vector3, B: Vector3):
	var link := node.areas[&"triLink"] as Node3D
	
	# Config link.
	var distance = A.distance_to(B)
	var position = (A + B) / 2
	# Set link length.
	link.scale.y = distance
	
	var d := A.direction_to(B) as Vector3
	d.x = 1 if d.x == 0 else 0
	d.y = 1 if d.y == 0 else 0
	d.z = 1 if d.y == 0 else 0
	link.look_at_from_position(position, A, d)
	
	link.set_collision_layer_and_mask_to_chunk_layer()
	#LinkModule.add_child(link)
	link_projection.add_child(link)
	
