extends Control

# Scenes
@onready var new_space_config_menu = preload("res://start_menu/offline_menu/new_space_config_menu.tscn")
@onready var local_space_metadata_panel = preload("res://start_menu/offline_menu/local_space_metadata_panel.tscn")

func _ready():
	# Check if the default space save folder exists
	create_default_space_folder()

func appear():
	visible = true
	refresh_space_list()

func refresh_space_list() -> void:
	clear_space_list()
	list_spaces()

# Function to create the default space save folder
func create_default_space_folder() -> void:
	if DirAccess.open(directory.spaces_dir_location) == null:
		var err = DirAccess.make_dir_absolute(directory.spaces_dir_location)
		if err != OK:
			printerr("Failed to create default folder, " + directory.spaces_dir_location + ', ' + error_string(err))
			return

# Function to clear the space list
func clear_space_list() -> void:
	var children = $HBoxContainer/TabContainer/local/VBoxContainer.get_children(false)
	for child in children:
		$HBoxContainer/TabContainer/local/VBoxContainer.remove_child(child)

# Function to list spaces
func list_spaces() -> void:
	var spaces = DirAccess.get_directories_at(directory.spaces_dir_location)
	for space_name in spaces:
		var space_metadata_panel = local_space_metadata_panel.instantiate()
		(space_metadata_panel.get_node("%description") as Label).text = space_name
		$HBoxContainer/TabContainer/local/VBoxContainer.add_child(space_metadata_panel)
		space_metadata_panel.connect("play_space", _on_play_space)

# New space configuration pop-up menu
var instantiated_new_space_config_menu
func _on_new_space_button_pressed():
	if instantiated_new_space_config_menu != null:
		pass  # Already displaying
	else:
		# Pop up new_space_config_menu
		instantiated_new_space_config_menu = new_space_config_menu.instantiate()
		add_child(instantiated_new_space_config_menu)
		# Connect signals
		(instantiated_new_space_config_menu.get_node('%cancel') as Button).pressed.connect(_on_new_space_config_menu_cancel_button_pressed)
		(instantiated_new_space_config_menu.get_node('%create') as Button).pressed.connect(_on_new_space_config_menu_create_button_pressed)

func _on_new_space_config_menu_cancel_button_pressed():
	instantiated_new_space_config_menu.queue_free()

func _on_new_space_config_menu_create_button_pressed():
	var new_space_config := instantiated_new_space_config_menu.get_config() as Dictionary
	instantiated_new_space_config_menu.queue_free()
	if new_space_config.name == "":
		new_space_config.name = Time.get_datetime_string_from_system()
		new_space_config.name = (new_space_config.name as String).replace(":", "-") # For OS, Windows.
	directory.update_space_location(new_space_config["name"])
	DirAccess.make_dir_absolute(directory.current_space_dir_location)
	DirAccess.make_dir_absolute(directory.chunk_dir_location)
	DirAccess.make_dir_absolute(directory.player_dir_location)
	# Build session_config
	var session_config = {"online" : false, "space_config" : {}}
	# Insert new_space_config
	session_config["space_config"] = new_space_config
	terminal.enter_session(session_config)

# Play space
func _on_play_space(space_name : String):
	print("Play space, ", space_name)
	# Build session_config
	var session_config = {"online" : false, "space_config" : {"name" : space_name}}
	directory.update_space_location(space_name)
	terminal.enter_session(session_config)
