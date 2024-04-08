extends Node3D

@onready var viewport = $panel/SubViewportContainer/SubViewport
var dflt_viewport_size

var typing_win_size := Vector2 (1.4,1.3)
var default_win_size := Vector2 (1, 0.5)
enum WindowMode {Typing, Default}
var WindowSizes := [typing_win_size, default_win_size]

var window_mode = WindowMode.Default
var is_typing := false

signal typing_started
signal typing_stopped


func _ready():
	dflt_viewport_size = viewport.size
	set_process(false)
	scale = Vector3(1,0,1)

func init():
	apply_current_window_mode()

func apply_current_window_mode():
	set_window_size(WindowSizes[window_mode])

var target_size : Vector3
var target_viewport_size : Vector2
var current_viewport_size : Vector2

func _process(delta):
	scale = lerp(scale, target_size, delta * 2.5)
	current_viewport_size = lerp(current_viewport_size, target_viewport_size, delta * 2.5)
	viewport.size = current_viewport_size.round()
	if scale.is_equal_approx(target_size) and target_viewport_size.is_equal_approx(current_viewport_size):
		set_process(false)

func set_window_size(size : Vector2):
	target_size = Vector3(size.x, size.y, 1)
	current_viewport_size = Vector2(viewport.size)
	target_viewport_size = Vector2(dflt_viewport_size.x * size.x, dflt_viewport_size.y * size.y)
	set_process(true)

func switch_window_size_between_default_and_typing_mode():
	match window_mode:
		WindowMode.Typing:
			window_mode = WindowMode.Default
		WindowMode.Default:
			window_mode = WindowMode.Typing
	apply_current_window_mode()


func start_typing():
	is_typing = true
	set_window_size(WindowSizes[WindowMode.Typing])
	input_line.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$panel/SubViewportContainer.mouse_filter = SubViewportContainer.MOUSE_FILTER_PASS
	emit_signal("typing_started")

func stop_typing():
	apply_current_window_mode()
	is_typing = false
	output.scroll_following = true
	input_line.release_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$panel/SubViewportContainer.mouse_filter = SubViewportContainer.MOUSE_FILTER_IGNORE
	emit_signal("typing_stopped")



@onready var input_line : LineEdit = %input_line 
@onready var output : RichTextLabel = %output

func _on_input_line_text_submitted(new_text):
	if new_text == "":
		stop_typing()
	else:
		input_line.clear()
		print_line(">"+new_text)
		terminal.handle(
			{
				"Hub" : terminal.local_hub,
				"ModuleContainer" : "Player",
				"Module" : "console",
				"Content" : {
					"Request" : "input",
					"Data" : new_text
				}
			}
		)
	if not window_mode == WindowMode.Typing:
		stop_typing()

func print_line(text : String):
	output.text += "\n" + text


func _on_output_gui_input(event):
	# when user scroll, stop scroll_following
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if is_typing:
					output.scroll_following = false
