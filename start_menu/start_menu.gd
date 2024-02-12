# Contains MainMenu code 
extends Control

var after_menu  # can be %MainMenu or %OfflineMenu
var previous_menu


func _ready():
#	TranslationServer.set_locale("kr")
#	%LoginButton.text = tr("login")
	
	# setup window
	window.scale_with_screen_size(window.size_main_menu)
	window.center()

	# connect start_menu signals to the terminal
	%ID_Input.grab_focus()
	(%LoginButton as Button).pressed.connect(terminal._on_login_button_pressed)
	(%RegisterButton as Button).pressed.connect(terminal._on_register_button_pressed)
	
	# set visible for MainMenu only for start_menu
	%MainMenu.visible = true
	%OfflineMenu.visible = false
	
	previous_menu = %MainMenu
	
	# GUI transition fade_in
	%Transition/ColorRect.visible = true
	%Transition.play("fade_in")


func _input(event):
	# login when user press enter
	if event is InputEventKey and event.pressed:
		if Input.is_action_pressed("ui_accept"):
			(%LoginButton).grab_focus()

func _on_offline_button_pressed():
	after_menu = %OfflineMenu
	%Transition.play("fade_out")
	
	
func _on_main_menu_button_pressed():
	after_menu = %MainMenu
	%Transition.play("fade_out")


# switch menu
func _on_transition_animation_finished(anim_name):
	if anim_name == "fade_out":
		previous_menu.visible = false
		if after_menu.has_method("appear"):
			after_menu.call("appear")
		else:
			after_menu.visible=true
		
		set_process_input(false)
		match after_menu.name:
			"OfflineMenu":
				window.scale_with_screen_size(window.size_offline_menu)
				window.center()
			"MainMenu":
				set_process_input(true)
				window.scale_with_screen_size(window.size_main_menu)
				window.center()
		
		# change scene before fade_in
		%Transition.play("fade_in")
		# update previous menu for next transition
		previous_menu = after_menu
