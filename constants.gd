extends Node

const HUB = "Hub"
const MODULE_CONTAINER = "ModuleContainer"
const MC_PLAYER = "Player"  # ModuleContainer.Player
const MC_SPACE = "Space"  # ModuleContainer.Space
const MODULE = "Module"

const CONTENT = "Content"
const REQUEST = "Request"
const TASK_ID = "TaskID"
const USER_ID = "UserID"

const COMMAND = "Command"

const RECORD = "Record"
const ENQUEUE = "Enqueue"
const DEQUEUE = "Dequeue"

const UNDO = "Undo"
const REDO = "Redo"

const PRIORITY = "Priority"
enum { IMMEDIATE, DEFERRED }
enum { ADMIN }

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
