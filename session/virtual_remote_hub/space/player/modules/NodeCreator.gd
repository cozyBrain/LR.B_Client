extends Node

@onready var space_module_chunk = %space_modules/Chunk as R_SpaceChunk

const tool_name := &"NodeCreator"

func handle(D : Dictionary):
	var C = D["Content"]
	var request := StringName(C.get("Request"))
	match request:
		&"create":
			var task_id = C.get("TaskID")
			var node_id_hashed  = C["id"]
			var node_pos = C["pos"]
			var new_node = node.scripts[node_id_hashed] ##TODO: Make this line safe.
			var pos = Vector3i(node_pos[0],node_pos[1],node_pos[2])
			space_module_chunk.insert_intobject(pos, new_node.new().create(node_id_hashed))
			
			# Feedback to the client that the operation has been done.
			# Client is going to accept the feedback to task_queue[task1, 2,..].
			if task_id != null:
				terminal.handle(
					{
						"Hub": terminal.local_hub,
						"ModuleContainer": "Player",
						"Module": tool_name,
						"Content": {
							"Response": task_id,
						},
					}
				)
			
			if D.get("CMR", true) == true:  # CommandManagerRecord
				# Create command
				var new_command = CreateNodeCommand.new(%offline_player.name, D)
				#TODO: send the command to the CommandManager
				
		
		&"remove":
			var task_id = C["TaskID"]
			var node_pos = C["pos"]
			var pos = Vector3i(node_pos[0],node_pos[1],node_pos[2])
			space_module_chunk.insert_intobject(pos, null)
			
			# Feedback to the client that the operation has been done.
			# Client is going to accept the feedback to task_queue[task1, 2,..].
			if task_id != null:
				terminal.handle(
					{
						"Hub": terminal.local_hub,
						"ModuleContainer": "Player",
						"Module": tool_name,
						"Content": {
							"Response": task_id,
						},
					}
				)


class CreateNodeCommand extends R_SpaceCommandManager.Command:
	func exec():
		command["CMR"] = false
		terminal.handle(command)
	func undo():
		# Reverse command.
		var undo_command = command.duplicate(true)
		var content: Dictionary = undo_command["Content"]
		content["Request"] = "remove"
		content.erase("TaskID")
		content.erase("id")
		# Observe target chunk.
		terminal.handle(
			{
				"Hub" : terminal.virtual_remote_hub,
				"ModuleContainer" : "Player",
				"Module" : "ChunkObserver",
				"Content" : {
					"Request": 	"command_observe",
					"observing_command": self,
					"pos": content["pos"],
				}
			}
		)
		terminal.handle(undo_command)
		# Unobserve the chunk.
		terminal.handle(
			{
				"Hub" : terminal.virtual_remote_hub,
				"ModuleContainer" : "Player",
				"Module" : "ChunkObserver",
				"Content" : {
					"Request": 	"command_unobserve",
					"observing_command": self,
					"pos": content["pos"], 
				}
			}
		)
	func redo():
		var redo_command = command.duplicate(true)
		redo_command["CM_Record"] = false
		var content: Dictionary = redo_command["Content"]
		content.erase("TaskID")
		# Observe target chunk.
		terminal.handle(
			{
				"Hub" : terminal.virtual_remote_hub,
				"ModuleContainer" : "Player",
				"Module" : "ChunkObserver",
				"Content" : {
					"Request": 	"command_observe",
					"observing_command": self,
					"pos": content["pos"], 
				}
			}
		)
		terminal.handle(redo_command)
		# Unobserve the chunk.
		terminal.handle(
			{
				"Hub" : terminal.virtual_remote_hub,
				"ModuleContainer" : "Player",
				"Module" : "ChunkObserver",
				"Content" : {
					"Request": 	"command_unobserve",
					"observing_command": self,
					"pos": content["pos"], 
				}
			}
		)
	
	# command structure.
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

	# command observe.
	#terminal.handle(
		#{
			#"Hub" : terminal.virtual_remote_hub,
			#"ModuleContainer" : "Player",
			#"Module" : "ChunkObserver",
			#"Content" : {
				#"Request": 	"command_observe",
				#"observing_command": self,
				#"pos": pos, 
			#}
		#}
	#)
