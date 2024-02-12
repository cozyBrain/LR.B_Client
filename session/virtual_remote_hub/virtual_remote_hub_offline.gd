extends Node

# ["ObjectInfoIndicator", "LinkCreator", "BoxConnector", "Hand", "NodeCreator", 
# "Selector", "Copier", "SupervisedLearningTrainer"]

@onready var player_module_container = %offline_player/player_modules
@onready var space_module_container = $space/space_modules

func handle(data : Dictionary):
	# select module container
	var module_container_selection = data["ModuleContainer"] as String
	var selected_module_container
	match module_container_selection:
		"Player":
			selected_module_container = player_module_container
		"Space":
			selected_module_container = space_module_container
		_:
			printerr("Invalid ModuleContainer selection: ", module_container_selection)
			return
	
	# get module from the container
	var module_selection := data["Module"] as String
	var module = selected_module_container.get_node(module_selection)
	if module == null:
		printerr("Invalid Module selection: ", module_selection)
		return
	# use module
	module.handle(data["Content"])
	
