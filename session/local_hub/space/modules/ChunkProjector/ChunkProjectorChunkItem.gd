## ChunkProjectorChunkItem manages the creation,
## management, and removal of links within individual chunks,
## ensuring efficient rendering of multiple links in a 3D space.
class_name ChunkProjectorChunkItem
extends Node3D

# Static variables and pools
static var intobject_pool := R_SpaceChunk.intobject_space_pool.new()

# Instance variables
var intobject: Array
var flobject: Array
var link_pointer := LinkProjectorChunkItemStrippedDown.new()
var intobject_changes: Array
var link_pointer_changes := {} # WARNING: READ_ONLY!
var collision_activated := false
var obj_painters: Dictionary = {}
var obj_painters_to_clear: Dictionary = {}
#var flobject_changes: Array
#var intobject_changes_mutex := Mutex.new()

@onready var chunk_area: Area3D = $Area3D

# Setup and resource management functions
func setup_intobject_array() -> void:
	intobject = intobject_pool.borrow_res()

func return_res() -> void:
	intobject_pool.return_res(intobject)

func rescale(chunk_size):
	chunk_area.scale = Vector3(chunk_size, chunk_size, chunk_size)

# Object painters management
func clear_obj_painters():
	for painter in obj_painters_to_clear.values():
		call_deferred("remove_child", painter)
	obj_painters_to_clear.clear()

func reflect_link_pointer_changes():
	for link_id in link_pointer_changes.keys():
		if link_pointer_changes[link_id] == null:
			link_pointer.unregister_link_pointer(link_id)
		else:
			link_pointer.register_link_pointer(link_id)

func get_registered_link_pointer() -> Dictionary:
	return link_pointer.links

# Main function to project changes
func project_changes():
	prepare_painters_for_clear()
	apply_intobject_changes()
	paint_objects()
	clear_obj_painters()
	if collision_activated:
		call_deferred("activate_collision")
	reflect_link_pointer_changes()

# Prepare painters for clearing
func prepare_painters_for_clear():
	obj_painters_to_clear.merge(obj_painters, true)
	obj_painters.clear()

# Apply changes to intobject
func apply_intobject_changes():
	for x in intobject_changes.size():
		for y in intobject_changes[x].size():
			for z in intobject_changes[x][y].size():
				apply_change_to_intobject(x, y, z, intobject_changes[x][y][z])

# Apply a single change to intobject
func apply_change_to_intobject(x, y, z, changes):
	if changes == null:
		intobject[x][y][z] = changes
	elif typeof(changes) == TYPE_DICTIONARY:
		merge_changes(x, y, z, changes)
		update_obj_painter(x, y, z)
	else:
		printerr("Error: ChunkProjectorChunkItem.apply_change_to_intobject(): Invalid changes type.")

# Merge changes into intobject
func merge_changes(x, y, z, changes):
	if intobject[x][y][z] == null:
		intobject[x][y][z] = Dictionary()
	intobject[x][y][z].merge(changes, true)

# Update obj_painter with changes
func update_obj_painter(x, y, z):
	var obj = intobject[x][y][z]
	var obj_properties = node.scripts[obj["id"]]
	var shape_id: StringName = obj_properties.get("shape_id")
	var color: Color = obj_properties.get("color")
	var pos := Vector3(x, y, z)
	
	var painter: obj_painter = obj_painters.get(shape_id)
	if painter == null:
		painter = create_new_painter(shape_id)
	
	painter.paint_at(pos, color)

# Create a new obj_painter
func create_new_painter(shape_id: StringName) -> obj_painter:
	var painter = obj_painter.new()
	painter.set_mesh(node.meshes[shape_id])
	painter.set_collision_shape(node.static_bodies[shape_id])
	obj_painters[shape_id] = painter
	return painter

# Paint all objects
func paint_objects():
	for painter in obj_painters.values():
		call_deferred("add_child", painter)
		painter.call_deferred("paint")

# Collision management
func activate_collision():
	for painter in obj_painters.values():
		painter.activate_cs()
	collision_activated = true

func deactivate_collision():
	for painter in obj_painters.values():
		painter.deactivate_cs()
	collision_activated = false



class obj_painter extends MultiMeshInstance3D:
	enum { iTransform, iColor, inst_data_size } # iColor means InstanceColor.
	
	var mm := MultiMesh.new()
	var cs # CollisionShape3D
	var collision_shapes: Array = []
	var inst_data: Array = []
	
	func _init():
		setup_multimesh()
	
	func setup_multimesh():
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.set_use_colors(true)
		multimesh = mm
	
	func set_mesh(m: Mesh):
		mm.mesh = m
	
	func set_collision_shape(c):
		cs = c
	
	func activate_cs(): # Activate collision shapes.
		for c in collision_shapes:
			c.get_node("CollisionShape3D").set_deferred("disabled", false)
	
	func deactivate_cs(): # Deactivate collision shapes.
		for c in collision_shapes:
			c.get_node("CollisionShape3D").set_deferred("disabled", true)
	
	func paint():
		mm.instance_count = inst_data.size()
		for i in range(mm.instance_count):
			var trans := inst_data[i][iTransform] as Transform3D
			var color := inst_data[i][iColor] as Color
			mm.set_instance_transform(i, trans)
			mm.set_instance_color(i, color)
			add_collision_shape(trans)
	
	func add_collision_shape(trans: Transform3D):
		var c = cs.instantiate()
		c.transform = trans
		add_child(c)
		collision_shapes.append(c)
	
	func paint_at(pos: Vector3, color: Color):
		var trans := Transform3D(Basis(), pos)
		var data := []
		data.resize(inst_data_size)
		data[iTransform] = trans
		data[iColor] = color
		inst_data.append(data)
	
	func clear():
		mm.instance_count = 0
		inst_data.clear()
