extends Node

const size_main_menu := Vector2(0.4, 0.4)
const size_offline_menu := Vector2(0.5, 0.5)
var session_window_size_scale := Vector2(0.7, 0.7)
@onready var screen_size : Vector2i = DisplayServer.screen_get_size() # display size
var current_window_size : Vector2i = DisplayServer.window_get_size()

func set_size_and_center(xy : Vector2i) -> void:
	current_window_size = xy
	DisplayServer.window_set_size(xy)
	center()

func set_size(xy : Vector2i) -> void:
	current_window_size = xy
	DisplayServer.window_set_size(xy)

func center():
	DisplayServer.window_set_position(Vector2(DisplayServer.screen_get_position()) + Vector2(screen_size)*0.5 - Vector2(current_window_size)*0.5)

func scale_with_screen_size(scale : Vector2):
	set_size(Vector2i(Vector2(screen_size) * scale))

func scale_with_screen_size_ratio_pivot_x(scale : Vector2, ratio : float = 16.0/9.0):
	var scaled_size = Vector2(screen_size) * scale.x
	scaled_size.y = scaled_size.x / ratio
	set_size(scaled_size)


func get_viewport_center_pos() -> Vector2:
	return Vector2(current_window_size) / 2
