extends MultiMeshInstance3D

var process_count_per_frame := 300

func _ready():
	var mm := MultiMesh.new()
	mm.mesh = $test_mesh.mesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	
	var x_size := 40 
	var z_size := 40
	var y_size := 40
	var i_count := x_size * z_size * y_size
	print(i_count)
	mm.set_use_colors(true) # must be set before instance_count set up
	mm.instance_count = i_count
	mm.visible_instance_count = i_count
	
	var process_count := 0
	for x in x_size:
		for z in z_size:
			for y in y_size:
				var i := y*y_size*y_size+x*x_size+z
#				var trans := Transform3D(Basis(), Vector3(x+randf_range(-1,1), y, z+randf_range(-1,1)))
				var trans := Transform3D(Basis(), Vector3(x+randf_range(-1,1), y, z+randf_range(-1,1))).rotated_local(Vector3(randi(),randi(),randi()).normalized(), randf())
				var thickness := randf_range(0,1)
				trans = trans.scaled_local(Vector3(thickness, 1, thickness))
				mm.set_instance_transform(i, trans)
				mm.set_instance_color(i, Color(thickness,1-thickness,0,1))
#				var node = $test_mesh.duplicate()
#				node.transform = trans
#				add_child(node)
#				if process_count >= process_count_per_frame:
#					await get_tree().physics_frame
#					process_count = 0
#				else:
#					process_count += 1
	self.multimesh = mm

func _physics_process(delta):
	print(Performance.get_monitor(Performance.TIME_FPS))
