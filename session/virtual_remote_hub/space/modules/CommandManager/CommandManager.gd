extends Node
class_name R_SpaceCommandManager

const module_name = &"CommandManager"

var global_undo_stack: HashLinkedList
var global_redo_stack: HashLinkedList
var user_stacks: Dictionary = {}
var next_command_id: int = 0
var max_stack_size: int = 100
var command_queue := ArrayQueue.new(5000)


#@onready var command_handle_timer := $command_handle_tick as Timer
#var command_handle_timer_interval := 0.05 # in seconds.
#func _ready():
	## Start ticks #
	#command_handle_timer.timeout.connect(handle_queued_command)
	#command_handle_timer.start(command_handle_timer_interval)

# Constructor
func _init():
	global_undo_stack = HashLinkedList.new(max_stack_size)
	global_redo_stack = HashLinkedList.new(max_stack_size)

func handle(D : Dictionary):
	var Content = D[c.CONTENT]
	match Content[c.REQUEST]:
		c.RECORD:
			var command = Content[c.COMMAND]
			record(command)
		#c.ENQUEUE:
			#var command = Content[c.COMMAND]
			#var user_id = Content[c.USER_ID]
			#enqueue(user_id, Command.new(user_id, command))
		c.UNDO:
			global_undo()
		_:
			assert(false, "Invalid request!")



# Add a user
func add_user(user_id: String, privilege: int) -> void:
	user_stacks[user_id] = UserStack.new(privilege, max_stack_size)

# record a command and add to the stack
func record(command: Command) -> void:
	if user_stacks.has(command.user_id):
		command.id = next_command_id
		next_command_id += 1
		user_stacks[command.user_id].add_command(command)
		global_undo_stack.add(command)
		global_redo_stack.clear()
		print("user_stacks: ", user_stacks[command.user_id].undo_stack.map)
		print("global_undo_stack: ", global_undo_stack.map)

# Enqueue a command and add to the stack
#func enqueue(user_id: String, command: Command) -> void:
	#if user_stacks.has(user_id):
		#command.user_id = user_id
		#command.id = next_command_id
		#next_command_id += 1
		#command_queue.enqueue(command)

#func handle_queued_command() -> void:
	#var command = command_queue.dequeue()
	#if command != null:
		#command.exec()
		#user_stacks[command.user_id].add_command(command)
		#global_undo_stack.add(command)
		#global_redo_stack.clear()

# Perform undo for a user
func undo(user_id: String) -> void:
	if user_stacks.has(user_id):
		var command = user_stacks[user_id].undo()
		if command:
			global_undo_stack.remove_by_id(command.id)
			global_redo_stack.add(command)

# Perform redo for a user
func redo(user_id: String) -> void:
	if user_stacks.has(user_id):
		var command = user_stacks[user_id].redo()
		if command:
			global_redo_stack.remove_by_id(command.id)
			global_undo_stack.add(command)

# Perform global undo
func global_undo() -> void:
	if global_undo_stack.size > 0:
		var last_command = global_undo_stack.remove_last()
		var user_id = last_command.user_id
		var command = last_command
		if user_stacks.has(user_id):
			user_stacks[user_id].undo_stack.remove_by_id(command.id)
			command.undo()
			user_stacks[user_id].redo_stack.add(command)
			global_redo_stack.add(command)

# Perform global redo
func global_redo() -> void:
	if global_redo_stack.size > 0:
		var last_command = global_redo_stack.remove_last()
		var user_id = last_command.user_id
		var command = last_command
		if user_stacks.has(user_id):
			user_stacks[user_id].redo_stack.remove_by_id(command.id)
			command.redo()
			user_stacks[user_id].undo_stack.add(command)
			global_undo_stack.add(command)


class Command extends RefCounted:
	var id: int
	var user_id: String
	var timestamp: int  ## Time.get_ticks_msec()
	var command: Dictionary
	#var composite_group_id: int
	
	# Constructor
	func _init(user_id: String, command: Dictionary = {}) -> void:
		self.timestamp = Time.get_ticks_msec()
		self.user_id = user_id
		self.command = command
	
	# Execute the command - abstract method to be overridden by subclasses
	func exec() -> void:
		assert(false, "Execute method not implemented")
	
	# Undo the command - abstract method to be overridden by subclasses
	func undo() -> void:
		assert(false, "Undo method not implemented")
	
	# Redo the command - by default, calls execute
	func redo() -> void:
		assert(false, "Redo method not implemented")
