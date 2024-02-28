extends Node

const spaces_dir_location = "user://spaces/" # must be end with '/'
var current_space_dir_location : String
var chunk_dir_location : String
var player_dir_location : String

const resource_packs_dir_location = "user://res_packs/"

func _ready():
	reset_current_space_dir_location()

func reset_current_space_dir_location():
	current_space_dir_location = spaces_dir_location
	chunk_dir_location = "/chunk"
	player_dir_location = "/player"


func update_space_location(space_name : String):
	reset_current_space_dir_location()
	current_space_dir_location += space_name
	chunk_dir_location = current_space_dir_location + chunk_dir_location
	player_dir_location = current_space_dir_location + player_dir_location

#region chunk
func load_chunk(pos : Vector3i) -> Chunk.chunk_item:
	var f = FileAccess.open_compressed(chunk_dir_location+'/'+stringify_chunk_pos(pos), FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return null
	var data = f.get_var(false)
	return Chunk.chunk_item.new().load_save_data(data)

func save_chunk(chunk : Chunk.chunk_item, pos : Vector3i):
	var f = FileAccess.open_compressed(chunk_dir_location+'/'+stringify_chunk_pos(pos), FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		printerr("failed to save chunk, position: ", pos, " ",error_string(FileAccess.get_open_error()))
		return
	var save_data := chunk.get_save_data()
	f.store_var(save_data, false)

func stringify_chunk_pos(pos : Vector3i) -> String:
	return var_to_str(pos.x)+','+var_to_str(pos.y)+','+var_to_str(pos.z)
#endregion

#region player
func load_player(id : String):
	var target_path: String = player_dir_location+'/'+id
	var f = FileAccess.open_compressed(target_path, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	if f == null:
		printerr("failed to load player at ", target_path+" ", error_string(FileAccess.get_open_error()))
		return null
	return f.get_var()
	
func save_player(id : String, save_data : Dictionary):
	var target_path: String = player_dir_location+'/'+id
	var f = FileAccess.open_compressed(target_path, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	if f == null:
		printerr("failed to save player at ", target_path+" ", error_string(FileAccess.get_open_error()))
		return
	f.store_var(save_data)
#endregion

const res_node_dir_location := "res://session/virtual_remote_hub/space/objects/nodes/"
var res_node_dirs = DirAccess.get_directories_at(res_node_dir_location)

const res_mesh_dir_location := "res://session/virtual_remote_hub/space/objects/shapes/"
var res_mesh_dirs = DirAccess.get_directories_at(res_mesh_dir_location)
const res_collision_shape_dir_location := "res://session/virtual_remote_hub/space/objects/shapes/"
var res_collision_shape_dirs = DirAccess.get_directories_at(res_collision_shape_dir_location)
