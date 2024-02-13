extends Node



func handle(data : Dictionary):
	# select module container
	var module_container_selection = data["ModuleContainer"] as String
	var selected_module_container
	match module_container_selection:
		"Player":
			selected_module_container = get_node("space_projection/player/player_modules")
		"Space":
			selected_module_container = get_node("space_projection/space_modules")
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
