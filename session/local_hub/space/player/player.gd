class_name client_player
extends CharacterBody3D


@onready var head = $head
@onready var _3d_hud = %"3d_hud_projector"
@onready var console = _3d_hud.get_node("console")
@onready var chunk_projection = %space_modules/chunk_projection as client_space_module_chunk_projection
@onready var chunk_observer = %player_modules/chunk_observer as client_player_module_chunk_observer

var speed : float = speed_default
var speed_default : float = 5
var speed_slow : float = 1
var speed_fast : float = 40
var lerp_speed : float = 13 # lower -> move smooth
var move_slow = false # toggle

var prev_position : Vector3
var prev_head_rotation : Vector2

var aim: Basis
var aim_speed: float = 0.4
var default_raycast_length: float = 64

signal head_moved


#region basic

func _ready():
	prev_position = position
	prev_head_rotation = get_head_rotation()
	
	set_raycast_length(default_raycast_length)
	
	# request spawn (get spawn pos from virual_remote_hub and sync)
	terminal.handle(
		{
			"Hub" : terminal.virtual_remote_hub,
			"ModuleContainer" : "Player",
			"Module" : "player_motion_sync",
			"Content" : {
				"Request" : "spawn",
				"ID" : "offline_player"
			}
		}
	)
	chunk_projection.update_visible_range(position, true)


func _physics_process(delta):
	# get direction of the camera
	aim = ($head/camera as Camera3D).get_camera_transform().basis
	#region player_keyboard_movement
	# set direction using aim and set speed
	var direction = Vector3()
	if not console.is_typing:
		if Input.is_action_pressed("front"):
			direction -= aim.z
		if Input.is_action_pressed("back"):
			direction += aim.z
		if Input.is_action_pressed("left"):
			direction -= aim.x
		if Input.is_action_pressed("right"):
			direction += aim.x
		if Input.is_action_pressed("up"):
			direction += aim.y
		if Input.is_action_pressed("down"):
			direction -= aim.y
		if Input.is_action_pressed("move_fast"):
			speed = speed_fast
			move_slow = false
		elif Input.is_action_just_pressed("move_slow"):
			speed = speed_slow
			if move_slow:
				move_slow = false
			else:
				move_slow = true
		elif not move_slow:
			speed = speed_default
	#endregion
	# set velocity
	velocity = lerp(velocity, direction.normalized()*speed, delta*lerp_speed)
	# move
	move_and_slide()
	# sync
	sync_position_and_head_rotation()




func _unhandled_input(event):
	# head rotation
	if event is InputEventMouseMotion:
		rotate_y(-deg_to_rad(event.relative.x)*aim_speed)
		head.rotate_x(-deg_to_rad(event.relative.y)*aim_speed)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
	if Input.is_action_just_pressed("ui_cancel"): # key Esc
		# inform virtual_remote_hub that the player is going to exit session
		# should save chunks & player
		terminal.handle(
			{
				"Hub" : terminal.virtual_remote_hub,
				"ModuleContainer" : "Player",
				"Module" : "player",
				"Content" : {
					"Request" : "exit_session",
				}
			}
		)
		terminal.exit_session()
	elif Input.is_action_just_pressed("console_switch_window_mode"): # key R
		console.switch_window_size_between_default_and_typing_mode()
	elif Input.is_action_just_pressed("console_type"): # key t
		console.start_typing() # Emit signal to let other modules ignore input.
		set_process_unhandled_input(false)
		


func _on_console_typing_stopped():
	set_process_unhandled_input(true)

func sync_position_and_head_rotation():
	# if head move
	if prev_position != position or prev_head_rotation != get_head_rotation():
		prev_position = position
		var current_head_rotation := get_head_rotation()
		prev_head_rotation = current_head_rotation
		var sync_data := {
				"Hub" : terminal.virtual_remote_hub,
				"ModuleContainer" : "Player",
				"Module" : "player_motion_sync",
				"Content" : {
					"sync_position" : [position.x,position.y,position.z], 
					"sync_head_rotation" : [current_head_rotation.x, current_head_rotation.y]
				}
			}
		
		# send sync_position data to terminal
		terminal.handle(sync_data)
		emit_signal("head_moved")
		chunk_projection.update_visible_range(position)

func get_head_rotation() -> Vector2:
	return Vector2(head.rotation.x, rotation.y)

func get_aim() -> Vector3:
	return -head.global_transform.basis.z
#endregion


var selected_tool
var previous_selected_tool

func select_tool(tool):
	deselect_tool()
	selected_tool = tool
	print(tool.tool_name, " selected!")

func deselect_tool():
	previous_selected_tool = selected_tool
	selected_tool = null
	if not previous_selected_tool == null:
		if previous_selected_tool.has_method("deselect"):
			previous_selected_tool.call("deselect")

func set_raycast_length(length: float):
	($head/laser_pointer as RayCast3D).target_position.z = -length
	$head/laser_pointer/chunks_detector.scale.z = length


#func _on_chunks_detector_detected(area):
	#print(area.get_node("..").position)


