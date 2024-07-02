extends RefCounted
class_name UserStack

var undo_stack: HashLinkedList
var redo_stack: HashLinkedList
var privilege: int

# Constructor
func _init(privilege: int, max_stack_size: int = 500) -> void:
	self.privilege = privilege
	undo_stack = HashLinkedList.new(max_stack_size)
	redo_stack = HashLinkedList.new(max_stack_size)

# Add command to the stack
func add_command(command: R_SpaceCommandManager.Command) -> void:
	undo_stack.add(command)
	redo_stack.clear()

# Perform undo
func undo() -> R_SpaceCommandManager.Command:
	if can_undo():
		var command = undo_stack.remove_first()
		command.undo()
		redo_stack.add(command)
		return command
	return null

# Perform redo
func redo() -> R_SpaceCommandManager.Command:
	if can_redo():
		var command = redo_stack.remove_first()
		command.redo()
		undo_stack.add(command)
		return command
	return null

# Check if undo is possible
func can_undo() -> bool:
	return undo_stack.size > 0

# Check if redo is possible
func can_redo() -> bool:
	return redo_stack.size > 0
