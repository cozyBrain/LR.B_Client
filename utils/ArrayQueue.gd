extends Node
class_name ArrayQueue

var queue: Array
var max_size: int

## Constructor
func _init(_max_size: int):
	max_size = _max_size

func enqueue(element) -> bool:
	if not is_full():
		queue.append(element)
		return true
	return false # Return false if the queue is full

## Remove the first n items from the queue and return them
func dequeue(n: int = 1):
	if queue.size() > 0:
		var dequeue_size = min(n, queue.size())  # Ensure we don't dequeue more than available
		var dequeued_items = queue.slice(0, dequeue_size)
		queue = queue.slice(dequeue_size)
		return dequeued_items
	return null

## Get the current size of the queue
func get_pending_count() -> int:
	return queue.size()
## Check if the queue is full
func is_full() -> bool:
	return queue.size() >= max_size
## Check if the queue is empty
func is_empty() -> bool:
	return queue.is_empty()
## Set the maximum size of the queue
func set_max_size(_max_size: int):
	max_size = _max_size
## Get the maximum size of the queue
func get_max_size() -> int:
	return max_size
