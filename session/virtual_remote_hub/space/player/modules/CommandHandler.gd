extends Node
class_name R_PlayerCommandHandler

const module_name = &"CommandHandler"

@onready var command_handle_timer := $command_handle_tick as Timer
var command_handle_timer_interval := 0.05 # in seconds.

## Commands in the queue will be sent to the command manager.
## Manages commands based on their priority.
var queue := ArrayQueue.new(2500) 

func _ready():
	# Start ticks #
	command_handle_timer.timeout.connect(handle_queued_command)
	command_handle_timer.start(command_handle_timer_interval)

func handle(D : Dictionary):
	var Content = D["Content"]
	# If content[c.PRIORITY] == c.IMMEDIATE, -> Immediately CommandManager.enqueue(command)
	# If a command with a priority higher than the threshold is received, its priority is downgraded.
	if Content.get(c.PRIORITY, c.DEFERRED) == c.IMMEDIATE:
		var command: Dictionary = Content["Command"]
		## Immediately execute the command.
		terminal.handle(command)
		#terminal.handle(
			#{
				#c.HUB: 				terminal.virtual_remote_hub,
				#c.MODULE_CONTAINER: c.MC_SPACE,
				#c.MODULE: 			R_SpaceCommandManager.module_name,
				#c.CONTENT: {
					#c.REQUEST: 		c.ENQUEUE,
					#c.USER_ID:		%offline_player.name,
					#c.COMMAND: 		command,
				#}
			#}
		#)
	else:
		var command: Dictionary = Content["Command"]
		# Enqueue command.
		queue.enqueue(command)

func handle_queued_command():
	if not queue.is_empty():
		var command = queue.dequeue()
		# Send the command to the CommandManager.
		


# Create node.
#terminal.handle(
	#{
		#c.HUB: 				terminal.virtual_remote_hub,
		#c.MODULE_CONTAINER: 	c.MCPLAYER,
		#c.MODULE: 				R_PlayerCommandHandler.module_name,
		#c.CONTENT: {
			#"Command": {
				#c.HUB: 				terminal.virtual_remote_hub,
				#c.MODULE_CONTAINER: 	c.MCPLAYER,
				#c.MODULE:				self.tool_name,
				#c.CONTENT: {
					#c.REQUEST: 		"create",
					#c.TASK_ID:			task.get_instance_id(),
					#"id": 				node_selection.hash(),
					#"pos":				[pos.x, pos.y, pos.z]
				#},
			#},
		#},
	#},
#)
