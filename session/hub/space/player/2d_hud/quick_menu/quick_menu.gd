extends Control

var current_menu
var previous_menu

var mouse_hovering_button # current mouse_hovering_button

var default_button_theme := load("res://session/hub/space/player/2d_hud/quick_menu/quick_menu_default_button_theme.tres")

# Design
#    -Connector
#    -Copier
#    -NodeCreator
#    -Selector
#    -Inspector
# Learning
#    -Supervision
#    -Reinforcement
#    -Selector
#    -Inspector

func get_center_pos() -> Vector2:
	return size/2

func _ready():
	visible = false
	# create categories
	# Design
	var new_button := Button.new()
	new_button.text = "Design"
	add_button(new_button, "./", true)
	# Learning
	new_button = Button.new()
	new_button.text = "Learning"
	add_button(new_button, "./", true)



func _unhandled_input(event):
	if event is InputEventKey:
		if Input.is_action_just_pressed("quick_menu"): # when 'Q' is just pressed, show quick_menu
			visible = true
			%player.set_process_unhandled_input(false)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			warp_mouse(get_center_pos())
			appear($main)
			go_back_to_previous()
			mouse_hovering_button = null
		elif Input.is_action_just_released("quick_menu"):
			if mouse_hovering_button != null: # this line must be executed first(before visible = false) or mouse_hovering_button will be set to null by mouse_exited signal of quick_menu_button
				mouse_hovering_button.hover_press()
			visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			%player.set_process_unhandled_input(true)
			clear_stage()
			previous_menu = current_menu



func appear(path):
	if not visible:
		return
	clear_stage()
	current_menu = path
	
	var number_of_buttons = current_menu.get_child_count()
	
	# max_buttons = 10
	var margin = 5
	var gap = (180.0-margin*2) / (number_of_buttons+1)
	var degree = -90+margin
	for button in current_menu.get_children():
		degree += gap
		button.visible = true
		button.set_position(calculate_circular_pos(get_center_pos()-button.size/2, degree, 150+abs(degree*0.5)))
		current_menu.remove_child(button)
		$stage.add_child(button)
	
	
	clear_sub_stage()
	# sub_menu which is appeared on the left.
	var sub_menu := []
	var dir = path
	if dir.name != "main":
		dir = dir.get_parent()
		while dir.name != "main":
			# create sub_button
			var sub_button := Button.new()
			sub_button.text = dir.name
			basic_setup_button(sub_button)
			sub_button.is_directory = true
			sub_button.dir = dir
			sub_button.quick_menu = self
			$sub_stage.add_child(sub_button)
			sub_menu.append(sub_button)
			dir = dir.get_parent()
	
	# if current_menu isn't main, show go_back_to_main button
	if current_menu.name != "main":
		var b = $sub/go_back_to_main
		sub_menu.append(b)
	else:
		$sub/go_back_to_main.visible = false
	
	sub_menu.reverse()
	margin = 15
	gap = (180.0-margin*2) / (sub_menu.size()+1)
	degree = 90 + margin
	for button in sub_menu:
		degree += gap
		button.visible = true
		button.set_position(calculate_circular_pos(get_center_pos()-button.size/2, degree, 100))

func clear_sub_stage():
	for child in $sub_stage.get_children():
		$sub_stage.remove_child(child)

func clear_stage():
	if current_menu != null:
		for child in $stage.get_children():
			$stage.remove_child(child)
			current_menu.add_child(child)
			child.visible = false


func add_button(new_button, path := "./", is_directory := false):
	var p = get_node("main/"+path)
	basic_setup_button(new_button)
	new_button.visible = false
	new_button.is_directory = is_directory
	new_button.quick_menu = self
	p.add_child(new_button)
	# edit for directory button
	if is_directory:
		pass
func basic_setup_button(button):
	button.set_script(load("res://session/hub/space/player/2d_hud/quick_menu/quick_menu_button.gd"))
	button.name = button.text
	button.theme = default_button_theme



func _on_go_back_to_main_pressed():
	appear($main)

func go_back_to_previous():
	if previous_menu != null:
		appear(previous_menu)


func calculate_circular_pos(origin: Vector2, angle_degrees: float, distance: float) -> Vector2:
	var angle_radians = deg_to_rad(angle_degrees)
	
	var new_x = origin.x + distance * cos(angle_radians)
	var new_y = origin.y + distance * sin(angle_radians)
	
	return Vector2(new_x, new_y)
