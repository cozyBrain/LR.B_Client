extends Node

var id := "offline_player"

@onready var player = %offline_player
@onready var space_module_chunk = %space_modules/chunk as Chunk

@onready var save_data := {
	String(get_path()) : {"id" : ""},
	String(player.get_path()) : {"position" : player.position, "rotation" : player.rotation},
	String(%offline_player/head.get_path()) : {"rotation_degrees" : %offline_player/head.rotation}
}



func handle(v : Dictionary):
	match v.get("Request"):
		"exit_session":
			print("handle_exit_session")
			print("pausing module, chunk")
			space_module_chunk.pause()
			print("saving player..")
			save_player()
			print("saving chunks...")
			save_chunks()



func load_player(id_to_load : String):
	print("load_player: ", id_to_load)
	var loaded_data = directory.load_player(id_to_load)
	if loaded_data == null:
		save_player()
	else:
		for path in loaded_data.keys():
			var n := get_node(path)
			for property in loaded_data[path]:
				n.set(property, loaded_data[path][property])
	print("loaded player: ", id)

func save_player():
	for path in save_data.keys():
		var n := get_node(path)
		for property in save_data[path]:
			save_data[path][property] = n.get(property)
	directory.save_player(id, save_data)

func save_chunks():
	space_module_chunk.unload_all_chunks()
