extends Node

const out_port := &"out_port"
const in_port := &"in_port"

var scripts: Dictionary  ## loaded scripts {id: gdscript, hashed_id: gdscript}
var meshes: Dictionary
var collision_shapes: Dictionary

func _ready():
	# preload
	load_nodes()
	# client_side program going to use these
	load_meshes()
	load_collision_shapes()


func load_nodes():
	for node_dir in directory.res_node_dirs:
		# load script
		scripts[StringName(node_dir)] = load(directory.res_node_dir_location+node_dir+'/'+node_dir.to_lower()+"_node.gd")
		scripts[node_dir.hash()] = scripts[StringName(node_dir)]
		

func load_meshes():
	for mesh_dir in directory.res_mesh_dirs:
		meshes[StringName(mesh_dir)] = load(directory.res_mesh_dir_location+mesh_dir+"/mesh.tres")
func load_collision_shapes():
	for cs_dir in directory.res_collision_shape_dirs:
		collision_shapes[StringName(cs_dir)] = load(directory.res_collision_shape_dir_location+cs_dir+"/cs.tscn")
