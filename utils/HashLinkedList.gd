extends RefCounted
class_name HashLinkedList

var head: LinkedListNode = null
var tail: LinkedListNode = null
var map: Dictionary = {}
var size: int = 0
var max_size: int

# Constructor.
func _init(max_size: int) -> void:
	self.max_size = max_size

# Add an element to the end of the list.
func add(element) -> void:
	var node = LinkedListNode.new(element)
	if tail:
		tail.next = node
		node.prev = tail
		tail = node
	else:
		head = node
		tail = node
	map[element.id] = node
	size += 1
	if size > max_size:
		remove_first()

## Remove and return the first element.
func remove_first() -> Object:
	if head:
		var node = head
		if head.next:
			head = head.next
			head.prev = null
		else:
			head = null
			tail = null
		map.erase(node.value.id)
		size -= 1
		return node.value
	return null

## Remove an element by ID.
func remove_by_id(id: int) -> bool:
	if map.has(id):
		var node = map[id]
		if node.prev:
			node.prev.next = node.next
		else:
			head = node.next
		if node.next:
			node.next.prev = node.prev
		else:
			tail = node.prev
		map.erase(id)
		size -= 1
		return true
	return false

# Get an element by ID.
func get_by_id(id: int) -> Object:
	return map.get(id, null)

# Clear the list.
func clear() -> void:
	head = null
	tail = null
	map.clear()
	size = 0


class LinkedListNode extends RefCounted:
	var value
	var next: LinkedListNode = null
	var prev: LinkedListNode = null
	func _init(value) -> void:
		self.value = value

