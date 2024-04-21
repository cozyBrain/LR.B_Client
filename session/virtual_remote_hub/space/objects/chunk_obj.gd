class_name Chunk_obj
extends RefCounted

static var chunk_space: Chunk ## Can be used after Chunk.init(). 
var parent_chunk: Chunk.chunk_item

var change_set: Dictionary
var queue_projection_update: Callable

## request parent_chunk to update projection.
func add_change(changed_variable: String, variable, enable_save_on_unload := true) -> void: 
	change_set[changed_variable] = variable
	queue_projection_update.call() # parent_chunk.queue_intobject_projection_update()
	parent_chunk.enable_save_on_unload(enable_save_on_unload)
## Called when obj's load_save_data() is called. id must be added. This won't request parent_chunk to update projection.
func add_initial_change(changed_variable: String, variable) -> void:
	change_set[changed_variable] = variable
func clear_change_set() -> void:
	change_set.clear()

func project_changes() -> Dictionary:
	var changes := change_set.duplicate(true)
	clear_change_set()
	return changes

func create(id_hashed: int) -> Chunk_obj: # called when this obj is created.
	add_initial_change("id", id_hashed)
	return self
