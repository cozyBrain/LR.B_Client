## By default, link_creator won't connect already interconnected objs.
## Right click : Add start point of the link.
## Left click  : Connect target from the start points.
## 'R' press   : Reset added start points.
class_name PlayerLinkCreator
extends Node

@onready var quick_menu = %quick_menu
@onready var pointer := $"../SpacePointer" as PlayerSpacePointer
@onready var unified_chunk_observer = %player_modules/UnifiedChunkObserver as PlayerUnifiedChunkObserver
@onready var link_projection = %space_modules/LinkProjector as SpaceLinkProjector
@onready var console_window = %"3d_hud_projector"/console
@onready var console = $"../console"

const tool_name := &"LinkCreator"

# link parameters
var start_points: Array

var requested_tasks: Dictionary

func handle(v: Dictionary):
	var response = v.get("Response")
	match response:
		null:
			pass
		var task_id:
			# Clear the task.
			var task = instance_from_id(task_id)
			if task != null:
				unified_chunk_observer.unobserve_deferred(task)
				requested_tasks.erase(task)


func _ready():
	register_quick_menu_button()
	set_process_unhandled_input(false)
	# Connect console_window's typing signal to ignore input when player is typing.
	console_window.connect("typing_started", _on_console_typing_started)
	console_window.connect("typing_stopped", _on_console_typing_stopped)

func _on_console_typing_started():
	set_process_unhandled_input(false)
func _on_console_typing_stopped():
	if %player.selected_tool == self:
		set_process_unhandled_input(true)


func register_quick_menu_button():
	# create [node_creator] button in the "Design" category.
	var category = "Design"
	var new_button := Button.new()
	new_button.text = tool_name
	new_button.connect("pressed", _on_tool_selected)
	quick_menu.add_button(new_button, category, true)
	

func _on_tool_selected():
	%player.select_tool(self)
	set_process_unhandled_input(true)

func deselect():
	set_process_unhandled_input(false)


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			var pos = pointer.get_pointer_position()
			if typeof(pos) == TYPE_VECTOR3I and pointer.current_mode == pointer.Mode.VoxelPointer:
				if event.button_index == MOUSE_BUTTON_LEFT:
					# Connect to the obj(pos) from the start_points.
					if start_points.is_empty():
						console.print_line(["No start points selected."])
					else:
						# Create task to observe target_chunk.
						var task := PlayerUnifiedChunkObserver.observing_task.new()
						# Register the task to clear the task later.
						requested_tasks[task] = true
						var links_to_create := []
						for point in start_points:
							var link = load("res://session/virtual_remote_hub/space/objects/shapes/triLink/area(visible).tscn").instantiate()
							link.transform = SpaceLinkProjector.align_link_and_get_transform(point, pos)
							#link_projection.add_child(link) # Visualize link.
							
							var calculated_chunkPosForLinkPointer = SpaceLinkProjector.calculateChunkPosForLinkPointer(point, pos, 0.5)
							# Add chunks_to_observe. (The task ignores duplication.)
							#for i in (calculated_chunkPosForLinkPointer[0] as Array).size():
							task.add_chunk_to_observe(calculated_chunkPosForLinkPointer[0]) # chunk pos for link pointer.
							task.add_chunk_to_observe([calculated_chunkPosForLinkPointer[1]]) # start_point chunk pos.
							task.add_chunk_to_observe([calculated_chunkPosForLinkPointer[2]]) # end_point chunk pos.
							var link_data: Array[Vector3i] = [point] # start_point
							link_data.append_array(calculated_chunkPosForLinkPointer[0])
							link_data.append(pos) # end_point
							#link_data.append(0) # Add channel data. ##TODO: deprecate channel.
							links_to_create.append(link_data)
						unified_chunk_observer.observe(task)
						# Wait until the chunk is guaranteed to be accessible.
						await task.done
						# Create links.
						terminal.handle(
							{
								"Hub": 				terminal.virtual_remote_hub,
								"ModuleContainer": 	"Player",
								"Module": 			tool_name,
								"Content": {
									"Request": 		"create",
									"TaskID":		task.get_instance_id(),
									"links":		links_to_create,
								},
							}
						)
						
				elif event.button_index == MOUSE_BUTTON_RIGHT: ##TODO: Visualize selected start_points.
					# Add point as start point of the link.
					# Append the point until player reset. (reset button is 'R' by default.)
					start_points.append(pos) ##TODO: Prevent point duplication.
					print("Added a start_point: ", pos)
					print("start_points: ", start_points)
	
	if Input.is_action_just_pressed("reset"):
		# Reset start_points.
		print("R pressed!")
		start_points.clear()




#Dictionary[link_id] = Dictionary[link_id] + 1


