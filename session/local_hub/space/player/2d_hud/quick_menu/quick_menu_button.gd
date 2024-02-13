extends Control

var is_directory : bool = false
var disable_directory_mode : bool = false
var dir = self
var quick_menu


var sub_menu : Array

func _ready():
	connect("pressed", _on_pressed)
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)

func _on_pressed():
	if disable_directory_mode:
		# only executed when hover_pressed
		print("button ", self.name, " hover_pressed")
		disable_directory_mode = false
		return
	if is_directory:
		# only executed when pressed, not hover_pressed
		_on_mouse_exited() # reset mouse_hovering_button of quick_menu
		quick_menu.appear(dir)

func hover_press():
	disable_directory_mode = true
	emit_signal("pressed")


func _on_mouse_entered():
	quick_menu.mouse_hovering_button = self

func _on_mouse_exited():
	quick_menu.mouse_hovering_button = null
