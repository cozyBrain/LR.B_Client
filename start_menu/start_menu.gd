# Contains MainMenu code 
extends Control

var after_menu  # can be %MainMenu or %OfflineMenu
var previous_menu

func _ready():
	setup()
	previous_menu = %MainMenu
	fade_in_transition()

func setup():
	setup_window()
	connect_signals()
	setup_menu_visibility()

func setup_window():
	window.scale_with_screen_size(window.size_main_menu)
	window.center()

func connect_signals():
	%ID_Input.grab_focus()
	(%LoginButton as Button).pressed.connect(terminal._on_login_button_pressed)
	(%RegisterButton as Button).pressed.connect(terminal._on_register_button_pressed)

func setup_menu_visibility():
	%MainMenu.visible = true
	%OfflineMenu.visible = false

func fade_in_transition():
	%Transition/ColorRect.visible = true
	%Transition.play("fade_in")

func _input(event):
	if event is InputEventKey and event.pressed:
		if Input.is_action_pressed("ui_accept"):
			(%LoginButton).grab_focus()

func _on_offline_button_pressed():
	switch_menu(%OfflineMenu)

func _on_main_menu_button_pressed():
	switch_menu(%MainMenu)

func switch_menu(menu):
	after_menu = menu
	%Transition.play("fade_out")

func _on_transition_animation_finished(anim_name):
	if anim_name == "fade_out":
		hide_previous_menu()
		show_next_menu()
		update_window()
		fade_in_transition()
		update_previous_menu()

func hide_previous_menu():
	previous_menu.visible = false

func show_next_menu():
	if after_menu.has_method("appear"):
		after_menu.call("appear")
	else:
		after_menu.visible = true

func update_window():
	match after_menu.name:
		"OfflineMenu":
			window.scale_with_screen_size(window.size_offline_menu)
		"MainMenu":
			window.scale_with_screen_size(window.size_main_menu)
			set_process_input(true)
	window.center()

func update_previous_menu():
	previous_menu = after_menu
