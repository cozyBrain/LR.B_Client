extends Node

@onready var quick_menu = %quick_menu
@onready var pointer := $"../pointer" as client_player_module_pointer
@onready var unified_chunk_observer = %player_modules/unified_chunk_observer as client_player_module_unified_chunk_observer


var node_selection_button := MenuButton.new()
var node_selection: String = ""

var tool_name := &"node_creator"

var requested_tasks: Dictionary

func handle(v: Dictionary):
	var response = v.get("Response")
	match response:
		null:
			pass
		var task_id:
			# clear the task.
			var task = instance_from_id(task_id)
			if task != null:
				unified_chunk_observer.unobserve_deferred(task)
				requested_tasks.erase(task)
				



func _ready():
	register_quick_menu_button()
	set_process_unhandled_input(false)


func register_quick_menu_button():
	# create [node_creator] button in the "Design" category
	var category = "Design"
	var new_button := Button.new()
	new_button.text = tool_name
	new_button.connect("pressed", _on_tool_selected)
	quick_menu.add_button(new_button, category, true)
	
	# add node_selection_button
	node_selection_button.text = "select_node"
	var popup = node_selection_button.get_popup()
	# get existing nodes
	for n in node.scripts:
		if typeof(n) == TYPE_STRING:
			popup.add_item(n)
	popup.connect("id_pressed", _on_node_selected)
	quick_menu.add_button(node_selection_button, category+'/'+tool_name, false)

func _on_tool_selected():
	%player.select_tool(self)
	set_process_unhandled_input(true)

func deselect():
	print(tool_name, " deselected!")
	set_process_unhandled_input(false)

func _on_node_selected(id : int):
	node_selection = node_selection_button.get_popup().get_item_text(id)
	# show which node is selected
	node_selection_button.text = "select [{selection}]".format({"selection":node_selection})


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			var pos = pointer.get_pointer_position()
			var chunk_pos_to_observe: Vector3i = Chunk.global_pos_to_chunk_pos(pos, client_space_module_chunk_projection.chunk_size)
			if typeof(pos) == TYPE_VECTOR3I:
				if event.button_index == MOUSE_BUTTON_LEFT and pointer.current_mode == pointer.Mode.VoxelPointer and not node_selection == "":
					# Create task to observe target_chunk.
					var task := client_player_module_unified_chunk_observer.observing_task.new()
					# Register the task to clear the task later.
					requested_tasks[task] = true
					task.add_chunk_to_observe(chunk_pos_to_observe)
					unified_chunk_observer.observe(task)
					# Wait until the chunk is guaranteed to be accessible.
					await task.done
					# Create node
					terminal.handle(
						{
							"Hub": 				terminal.virtual_remote_hub,
							"ModuleContainer": 	"Player",
							"Module": 			tool_name,
							"Content": {
								"Request": 		"create_node",
								"TaskID":		task.get_instance_id(),
								"id": 			node_selection.hash(),
								"pos":			[pos.x, pos.y, pos.z]
							},
						}
					)
				elif event.button_index == MOUSE_BUTTON_RIGHT:
					# remove node
					print(
						{
							"Hub": 				terminal.virtual_remote_hub,
							"ModuleContainer": 	"Player",
							"Module": 			tool_name,
							"Content": {
								"Request": 		"remove_node",
								"pos": 			[pos.x, pos.y, pos.z],
							},
						}
					)

