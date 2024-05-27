class_name PlayerSpacePointer
extends Node

const tool_name := &"SpacePointer"

@onready var player_head = %player/head
@onready var laser_pointer : RayCast3D = %player/head/laser_pointer
@onready var voxel_pointer = preload("res://session/local_hub/space/player/modules/SpacePointer/voxel_pointer.tscn").instantiate()
@onready var console_window = %"3d_hud_projector"/console

@onready var console = $"../console"

@onready var quick_menu = %quick_menu

enum Mode {LaserPointer, VoxelPointer, NumOfModes}
var ModeName := {
	Mode.LaserPointer : "LaserPointer",
	Mode.VoxelPointer : "VoxelPointer"
}

var current_mode := Mode.LaserPointer


func _ready():
	# apply current_mode
	apply_mode()
	register_quick_menu_button()
	# Connect console_window's typing signal to ignore input when player is typing.
	console_window.connect("typing_started", _on_console_typing_started)
	console_window.connect("typing_stopped", _on_console_typing_stopped)

func _on_console_typing_started():
	set_process_unhandled_input(false)
func _on_console_typing_stopped():
	#if %player.selected_tool == self:
	set_process_unhandled_input(true)

func _on_inspect_position():
	print_position()

func _on_tool_selected():
	%player.select_tool(self)
func deselect():
	print(tool_name, " deselected")

func register_quick_menu_button():
	var category = "Design"
	
	var new_button = Button.new()
	new_button.text = "pointer"
	new_button.connect("pressed", _on_tool_selected)
	quick_menu.add_button(new_button, category, true)
	
	new_button = Button.new()
	new_button.text = "inspect_position"
	new_button.connect("pressed", _on_inspect_position)
	quick_menu.add_button(new_button, category+"/pointer", false)


func handle(options : Dictionary): # unsafe,. invalid options are handled after execution
	var option_name = "_"
	if options.has(option_name):
		if not options[option_name].is_empty():
			var option_without_arg = options[option_name][0]
			match option_without_arg:
				"scroll_mode":
					scroll_mode()
				_:
					console.print_invalid_option(option_without_arg)
	options.erase(option_name)
	
	# handle option, "-get"
	option_name = "-get"
	if options.has(option_name):
		var args := options[option_name] as Array
		if not args.is_empty():
			var arg = args[0]
			match arg:
				"position", "pos":
					print_position()
				_:
					console.print_invalid_arg_for_option(arg, option_name)
	options.erase(option_name)
	
	# handle invalid options
	for invalid_option in options.keys():
		console.print_invalid_option(invalid_option)

## TODO: update code in the case, Mode.LaserPointer.
func get_pointer_position():
	match current_mode:
		Mode.VoxelPointer:
			return voxel_pointer_position as Vector3i
		Mode.LaserPointer:
			if last_laser_pointer_collision_position == last_laser_pointer_collision_position.round():
				return Vector3i(last_laser_pointer_collision_position)
			return last_laser_pointer_collision_position as Vector3


func print_position():
	match current_mode:
		Mode.VoxelPointer:
			console.print_line(["voxel_pointer_position: ",var_to_str(voxel_pointer_position)])
		Mode.LaserPointer:
			console.print_line(["last_laser_pointer_collision_position: ",var_to_str(last_laser_pointer_collision_position)])

func _process(delta : float):
	match current_mode:
		Mode.VoxelPointer: # start voxel_pointer motion until reach to the target position
			if not voxel_pointer_position.is_equal_approx(voxel_pointer.global_position):
				voxel_pointer_update(delta)

func _physics_process(_delta):
	laser_pointer_detected_obj = laser_pointer.get_collider()
	if laser_pointer_detected_obj != null:
		last_laser_pointer_collision_position = laser_pointer_detected_obj.global_position
	

func scroll_mode():
	exit_mode()
	if current_mode+1 == Mode.NumOfModes:
		@warning_ignore("int_as_enum_without_cast")
		current_mode = 0
	else:
		@warning_ignore("int_as_enum_without_cast")
		current_mode += 1
	apply_mode()

func apply_mode():
	match current_mode:
		Mode.LaserPointer:
			$"../../head/hud/2d_hud/CenterContainer/Crosshair".visible = true
		Mode.VoxelPointer:
			add_child(voxel_pointer)
			voxel_pointer_init()
			voxel_pointer_update()
			$"../../head/hud/2d_hud/CenterContainer/Crosshair".visible = false
func exit_mode():
	match current_mode:
		Mode.LaserPointer:
			pass
		Mode.VoxelPointer:
			remove_child(voxel_pointer)



func _unhandled_input(event):
	if event is InputEventKey:
		if Input.is_action_just_pressed("ui_text_indent"): # when tab is just pressed, change mode
			scroll_mode()
			
	match current_mode:
		Mode.LaserPointer:
			if event is InputEventMouseButton:
				if event.is_pressed():
					if event.button_index == MOUSE_BUTTON_LEFT:
						print(laser_pointer_detected_obj)
		Mode.VoxelPointer:
			if event is InputEventMouseButton:
				if event.is_pressed():
					if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
						voxel_distance -= 0.5
					elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
						voxel_distance += 0.5
					voxel_distance = clamp(voxel_distance, 1, 50)
					voxel_pointer_update()

# laser_pointer
var laser_pointer_detected_obj
var last_laser_pointer_collision_position: Vector3

# voxel_pointer
var voxel_distance = 3
var voxel_pointer_position: Vector3
var voxel_pointer_motion_speed = 30
func voxel_pointer_init():
	voxel_pointer.global_position = %player.global_position
func voxel_pointer_update(delta : float = 0) -> void:
	voxel_pointer_position = (%player.global_position + %player.get_aim() * voxel_distance).round()
	voxel_pointer.global_position = lerp(voxel_pointer.global_position, voxel_pointer_position, delta*voxel_pointer_motion_speed)

func _on_player_head_moved():
	match current_mode:
		Mode.VoxelPointer:
			voxel_pointer_update()
