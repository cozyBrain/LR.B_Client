extends Node

@onready var space_module_chunk = %space_modules/chunk as Chunk

var tool_name := &"node_creator"

func handle(v : Dictionary):
	var request := StringName(v.get("Request"))
	match request:
		&"create_node":
			var task_id = v["TaskID"]
			var node_id_hashed  = v["id"]
			var node_pos = v["pos"]
			var new_node = node.scripts[node_id_hashed]
			var pos = Vector3i(node_pos[0],node_pos[1],node_pos[2])
			space_module_chunk.insert_intobject(pos, new_node.new().create(node_id_hashed))
			# Feedback to the client that the operation has been done.
			# Client is going to accept the feedback to task_queue[task1, 2,..].
			terminal.handle(
				{
					"Hub": terminal.local_hub,
					"ModuleContainer": "Player",
					"Module": tool_name,
					"Content": {
						"Response": task_id,
					},
				}
			)
			


# create node
#terminal.handle(
	#{
		#"Hub": 				terminal.virtual_remote_hub,
		#"ModuleContainer": 	"Player",
		#"Module": 				tool_name,
		#"Content": {
			#"Request": 		"create_node",
			#"id": 				node_selection,
			#"pos":				[pos.x, pos.y, pos.z]
		#},
	#}
#)
