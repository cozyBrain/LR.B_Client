class_name proj_link_chunk_item # chunk item that renders links.
extends MultiMeshInstance3D


var links: Dictionary = {}

func increment_link_observation_count(link_id: Array):
	if links.get(link_id) == null: # New link data.
		links[link_id] = 1
		##TODO: Render the connection.
		
		
	else: # if the link is already rendered.
		links[link_id] += 1

func erase_link(link_id: Array):
	links.erase(link_id)
	##TODO: Undo rendered connection.
	
	pass


func project_changes():
	# Get obj_painters to clear right after painting latest one.
	link_painters_to_clear.merge(link_painters, true)
	link_painters.clear()
	# Merge intobject_changes into intobject.
	
	##TODO: Iterate link_changes.
	var obj = null
	
	# Get basic properties of the obj.
	var obj_properties = node.scripts[obj["id"]]
	var shape_id: StringName = obj_properties.get("shape_id")
	var color: Color = obj_properties.get("color")
	var pos := Vector3()
	# Get painter with shape_id.
	var painter: link_painter = link_painters.get(shape_id)
	if painter == null:
		# create and setup new obj_painter for the shape.
		painter = link_painter.new()
		painter.set_mesh(node.meshes[shape_id])
		painter.set_collision_shape(node.static_bodies[shape_id])
		link_painters[shape_id] = painter
	
	painter.paint_at(pos, color)
	
	# Paint
	for l_painter in link_painters.values():
		call_deferred("add_child", l_painter)
		l_painter.call_deferred("paint")
	
	# Clear obj painters in the obj_painters_to_clear.
	clear_obj_painters()

func clear_obj_painters():
	for painter in link_painters_to_clear.values():
		call_deferred("remove_child", painter)
	link_painters_to_clear.clear()


var link_painters: Dictionary
var link_painters_to_clear: Dictionary

class link_painter extends MultiMeshInstance3D:
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
