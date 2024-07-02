extends Node

# ["ObjectInfoIndicator", "LinkCreator", "BoxConnector", "Hand", "NodeCreator", 
# "Selector", "Copier", "SupervisedLearningTrainer"]

@onready var player_module_container = %offline_player/player_modules
@onready var space_module_container = $space/space_modules

var handler := Thread.new()


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
	#module.handle(data["Content"])
	if handler.is_started():
		handler.wait_to_finish()
	handler.start(h.bind(module, data))

func h(module: Node, data):
	module.call_thread_safe("handle", data)

	## Create task to observe target_chunk.
	#var task := PlayerUnifiedChunkObserver.observing_task.new()
	## Register the task to clear the task later.
	#requested_tasks[task] = true
	#task.add_chunk_to_observe([chunk_pos_to_observe])
	#unified_chunk_observer.observe(task)
	## Wait until the chunk is guaranteed to be accessible.
	#await task.done
	## Create node.
	#terminal.handle(
		#{
			#"Hub": 				terminal.virtual_remote_hub,
			#"ModuleContainer": 	"Player",
			#"Module": 			tool_name,
			#"Content": {
				#"Request": 		"create",
				#"TaskID":		task.get_instance_id(),
				#"id": 			node_selection.hash(),
				#"pos":			[pos.x, pos.y, pos.z]
			#},
		#}
	#)

func _exit_tree():
	if handler.is_started():
		handler.wait_to_finish()
