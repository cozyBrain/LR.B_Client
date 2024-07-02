class_name PlayerMotionSync_R
extends Node

const module_name := &"PlayerMotionSync"

@onready var player_module_chunk_projection := $"../ChunkProjector" as R_PlayerChunkProjector
@onready var space_module_chunk := %space_modules/Chunk as R_SpaceChunk
@onready var player_module_player := $"../Player"
@onready var player = %offline_player


func handle(C : Dictionary):
	C = C["Content"]
	var head_rotation
	match C.get("Request"):
		"spawn":
			print("request spawn received!")
			# init chunk
			space_module_chunk.init()
			# load player
			player_module_player.load_player(C.ID)
			var position = player.position
			head_rotation = %offline_player/head.rotation.x
			var player_rotation = %offline_player.rotation.y
			# sync
			terminal.handle(
				{
					"Hub" : terminal.local_hub,
					"ModuleContainer" : "Player",
					"Module" : module_name,
					"Content" : {
						"sync_position" : [position.x,position.y,position.z], 
						"sync_head_rotation" : [head_rotation, player_rotation]
					}
				}
			)
	
	
	# sync head_rotation
	head_rotation = C.get("sync_head_rotation")
	if head_rotation != null:
		%offline_player/head.rotation.x = head_rotation[0]
		%offline_player.rotation.y = head_rotation[1]
	# sync pos
	var pos = C.get("sync_position")
	if pos != null:
		player.position = Vector3(pos[0], pos[1], pos[2])
		
#	print("sync -> ", %player/head.global_rotation_degrees, " / ", %player.position)
