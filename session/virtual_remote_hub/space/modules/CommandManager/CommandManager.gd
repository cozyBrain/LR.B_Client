extends Node
class_name R_SpaceCommandManager


var global_undo_stack: HashLinkedList
var global_redo_stack: HashLinkedList
var user_stacks: Dictionary = {}
var next_command_id: int = 0
var max_stack_size: int = 100


# Constructor
func _init():
	global_undo_stack = HashLinkedList.new(max_stack_size)
	global_redo_stack = HashLinkedList.new(max_stack_size)

# Add a user
func add_user(user_id: String, privilege: int) -> void:
	user_stacks[user_id] = UserStack.new(privilege, max_stack_size)

# Execute a command and add to the stack
func execute_command(user_id: String, command: Command) -> void:
	if user_stacks.has(user_id):
		command.id = next_command_id
		command.user_id = user_id
		next_command_id += 1
		command.execute()
		user_stacks[user_id].add_command(command)
		global_undo_stack.add(command)
		global_redo_stack.clear()

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
		var last_command = global_undo_stack.remove_first()
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
		var last_command = global_redo_stack.remove_first()
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
