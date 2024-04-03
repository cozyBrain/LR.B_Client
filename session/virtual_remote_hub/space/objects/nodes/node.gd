
extends Node

const out_port := &"out_port"
const in_port := &"in_port"

var scripts: Dictionary  ## loaded scripts {id: gdscript, hashed_id: gdscript}
var meshes: Dictionary
var static_bodies: Dictionary
var areas: Dictionary

func _ready():
	# preload
	load_nodes()
	# client_side program going to use these
	load_meshes()
	load_static_bodies()
	load_areas()


func load_nodes():
	for node_dir in directory.res_node_dirs:
		# load script
		scripts[StringName(node_dir)] = load(directory.res_node_dir_location+node_dir+'/'+node_dir.to_lower()+"_node.gd")
		scripts[node_dir.hash()] = scripts[StringName(node_dir)]
		

func load_meshes():
	for mesh_dir in directory.res_mesh_dirs:
		meshes[StringName(mesh_dir)] = load(directory.res_mesh_dir_location+mesh_dir+"/mesh.tres")
func load_static_bodies():
	for dir in directory.res_static_body_dirs:
		static_bodies[StringName(dir)] = load(directory.res_static_body_dir_location+dir+"/static_body.tscn")
func load_areas():
	for dir in directory.res_area_dirs:
		areas[StringName(dir)] = load(directory.res_area_dir_location+dir+"/area.tscn")

