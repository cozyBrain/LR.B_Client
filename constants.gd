extends Node

const HUB = "Hub"
const MODULE_CONTAINER = "ModuleContainer"
const MCPLAYER = "Player"  # ModuleContainer.Player
const MCSPACE = "Space"  # ModuleContainer.Space
const MODULE = "Module"

const CONTENT = "Content"
const REQUEST = "Request"
const TASK_ID = "TaskID"


					#terminal.handle(
						#{
							#"Hub": 				terminal.virtual_remote_hub,
							#"ModuleContainer": 	"Player",
							#"Module": "CommandHandler",
							#"Content": {
								#"Command": {
									#"Hub": 				terminal.virtual_remote_hub,
									#"ModuleContainer": 	"Player",
									#"Content": {
										#"Request": 		"create",
										#"TaskID":		task.get_instance_id(),
										#"id": 			node_selection.hash(),
										#"pos":			[pos.x, pos.y, pos.z]
									#},
								#},
							#},
						#},
					#)
