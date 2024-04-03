extends Node

@onready var quick_menu = %quick_menu
@onready var pointer := $"../pointer" as client_player_module_pointer
@onready var unified_chunk_observer = %player_modules/unified_chunk_observer as client_player_module_unified_chunk_observer
@onready var link_projection = %space_modules/link_projection as client_space_module_link_projection


var tool_name := &"link_creator"

func _ready():
	register_quick_menu_button()
	set_process_unhandled_input(false)


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
	
