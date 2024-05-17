class_name ChunkProjectorChunkItem # chunk item of the SpaceChunkProjector
extends Node3D

static var intobject_pool := R_SpaceChunk.intobject_space_pool.new()
var intobject: Array # intobject[x][y][z]
var flobject: Array
var link_pointer := LinkProjectorChunkItemStrippedDown.new()
var intobject_changes: Array
var link_pointer_changes := {} ##WARNING: READ_ONLY!
#var flobject_changes: Array

#var intobject_changes_mutex := Mutex.new()

var collision_activated := false

@onready var chunk_area: Area3D = $Area3D

func setup_intobject_array() -> void:
	intobject = intobject_pool.borrow_res()
func return_res() -> void:
	intobject_pool.return_res(intobject)


func rescale(chunk_size):
	chunk_area.scale = Vector3(chunk_size, chunk_size, chunk_size)


func clear_obj_painters():
	for painter in obj_painters_to_clear.values():
		call_deferred("remove_child", painter)
	obj_painters_to_clear.clear()

func reflect_link_pointer_changes():
	for link_id in link_pointer_changes.keys():
		# if link_pointer_changes[link_id] is null, this means that the link has been removed. This should be reflected.
		if link_pointer_changes[link_id] == null:
			link_pointer.unregister_link_pointer(link_id)
		else:
			link_pointer.register_link_pointer(link_id)
func get_registered_link_pointer() -> Dictionary:
	return link_pointer.links

func project_changes():
	# Get obj_painters to clear right after painting latest one.
	obj_painters_to_clear.merge(obj_painters, true)
	obj_painters.clear()
	# Merge intobject_changes into intobject.
	for x in intobject_changes.size():
		for y in intobject_changes[x].size():
			for z in intobject_changes[x][y].size():
				var changes = intobject_changes[x][y][z]
				match typeof(changes):
					TYPE_NIL:
						intobject[x][y][z] = changes
					_:
						if typeof(changes) == TYPE_DICTIONARY:
							# Update changes.
							if intobject[x][y][z] == null:
								intobject[x][y][z] = Dictionary()
							intobject[x][y][z].merge(changes, true)
						
						var obj = intobject[x][y][z]
						
						##TODO: Get obj properties(inport & outport) and reflect to the link_pointer_changes.
						
						
						# Get basic properties of the obj.
						var obj_properties = node.scripts[obj["id"]]
						var shape_id: StringName = obj_properties.get("shape_id")
						var color: Color = obj_properties.get("color")
						var pos := Vector3(x, y, z)
						# Get painter with shape_id.
						var painter: obj_painter = obj_painters.get(shape_id)
						if painter == null:
							# create and setup new obj_painter for the shape.
							painter = obj_painter.new()
							painter.set_mesh(node.meshes[shape_id])
							painter.set_collision_shape(node.static_bodies[shape_id])
							obj_painters[shape_id] = painter
						
						painter.paint_at(pos, color)
						
						# Project flobject
						
						
	# Paint
	for painter in obj_painters.values():
		call_deferred("add_child", painter)
		painter.call_deferred("paint")
	
	
	
	# Clear obj painters in the obj_painters_to_clear.
	clear_obj_painters()
	# activate_collision() after painter.paint() if collision is activated.
	if collision_activated:
		call_deferred("activate_collision")
	
	
	reflect_link_pointer_changes()



func activate_collision():
	for painter in obj_painters.values():
		painter.activate_cs()
	collision_activated = true
	
func deactivate_collision():
	for painter in obj_painters.values():
		painter.deactivate_cs()
	collision_activated = false

var obj_painters: Dictionary
var obj_painters_to_clear: Dictionary

class obj_painter extends MultiMeshInstance3D:
	enum {iTransform, iColor, inst_data_size} ## iColor means InstanceColor.
	var mm := MultiMesh.new()
	var cs ## CollisionShape
	var collision_shapes: Array ## Contains collision_shapes of the instances.
	var inst_data: Array ## instance_data
	
	func set_mesh(m: Mesh):
		mm.mesh = m
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.set_use_colors(true)
		multimesh = mm
	func set_collision_shape(c):
		cs = c
	
	func activate_cs(): ## Activate collision shapes.
		for c in collision_shapes:
			c.get_node("CollisionShape3D").set_deferred("disabled", false)
	func deactivate_cs(): ## Deactivate collision shapes.
		for c in collision_shapes:
			c.get_node("CollisionShape3D").set_deferred("disabled", true)
	
	func paint():
		var inst_count := inst_data.size()
		mm.instance_count = inst_count
		for i in inst_count:
			# get paint data from inst_data
			var trans := inst_data[i][iTransform] as Transform3D
			var color := inst_data[i][iColor] as Color
			mm.set_instance_transform(i, trans)
			mm.set_instance_color(i, color)
			# add collision shape for the instance.
			var c = cs.instantiate()
			c.transform = trans
			add_child(c)
			collision_shapes.append(c)
			
	
	func paint_at(pos: Vector3, color: Color):
		var trans := Transform3D(Basis(), Vector3(pos.x,pos.y,pos.z))
		# build data and append into inst_data for the paint
		var data := []
		data.resize(inst_data_size)
		data[iTransform] = trans
		data[iColor] = color
		inst_data.append(data)
	
	func clear():
		mm.instance_count = 0
		inst_data.clear()


#func _ready():
	#var mm := MultiMesh.new()
	#mm.mesh = $test_mesh.mesh
	#mm.transform_format = MultiMesh.TRANSFORM_3D
	#
	#mm.set_use_colors(true) # must be set before instance_count set up
	#mm.instance_count = i_count
	#
	#var process_count := 0
	#for x in x_size:
		#for z in z_size:
			#for y in y_size:
				#var i := y*y_size*y_size+x*x_size+z
#				var trans := Transform3D(Basis(), Vector3(x+randf_range(-1,1), y, z+randf_range(-1,1)))
				#trans = trans.scaled_local(Vector3(thickness, 1, thickness))
				#mm.set_instance_transform(i, trans)
				#mm.set_instance_color(i, Color(thickness,1-thickness,0,1))
	
	#self.multimesh = mm
