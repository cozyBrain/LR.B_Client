extends Node

@onready var quick_menu = %quick_menu
@onready var pointer := $"../pointer" as client_player_module_pointer
@onready var unified_chunk_observer = %player_modules/unified_chunk_observer as client_player_module_unified_chunk_observer

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

	# config link
	#var distance = A.translation.distance_to(B.translation)
	#var position = (A.translation + B.translation) / 2
	#var direction = A.translation.direction_to(B.translation)
	#setLength(distance)
	#var d = direction
	#d.x = 1 if d.x == 0 else 0
	#d.y = 1 if d.y == 0 else 0
	#d.z = 1 if d.y == 0 else 0
	#look_at_from_position(position, A.translation, d)
