extends Node

@onready var chunk = %space_modules/Chunk as R_SpaceChunk

const tool_name := &"LinkCreator"

func handle(v : Dictionary):
	var request := StringName(v.get("Request"))
	match request:
		&"create":
			var task_id = v["TaskID"]
			var links_to_create = v["links"]
			# Create links...
			print("received links_to_create: ", links_to_create)
			for link_data in links_to_create:
				link_data = link_data as Array
				var link_data_size: int = link_data.size()
				
				# Extract start&end point from the link_data.
				var spoint = link_data[0] # start_point
				var epoint = link_data[link_data_size-1] # end_point
				#var channel = link_data[link_data_channel_idx]
				# Connect spoint node.
				var spoint_chunk := chunk.get_chunk(R_SpaceChunk.global_pos_to_chunk_pos(spoint, chunk.chunk_size))
				var spoint_intobject = spoint_chunk.get_intobject(R_SpaceChunk.global_pos_to_local_intobject_pos(spoint, R_SpaceChunk.chunk_size))
				if spoint_intobject != null:
					spoint_intobject.connect_port(epoint, node.out_port)
				# Connect epoint node.
				var epoint_chunk := chunk.get_chunk(R_SpaceChunk.global_pos_to_chunk_pos(epoint, chunk.chunk_size))
				var epoint_intobject = epoint_chunk.get_intobject(R_SpaceChunk.global_pos_to_local_intobject_pos(epoint, R_SpaceChunk.chunk_size))
				if spoint_intobject != null && epoint_intobject != null:
					epoint_intobject.connect_port(spoint, node.in_port)
				# minimum link data size = [(0,0,0), (5,5,5)] # spoint, epoint.
				if link_data_size >= 3: # Register link pointer only when [spoint, lp_pos, epoint].
					# Register link pointers.
					var lp := [spoint, epoint]
					for i in range(1, link_data_size-2):
						var lp_pos = link_data[i]
						var c = chunk.get_chunk(lp_pos)
						c.insert_link_pointer(lp)
				
				
			
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


# Create links.
#terminal.handle(
	#{
		#"Hub": 				terminal.virtual_remote_hub,
		#"ModuleContainer": 	"Player",
		#"Module": 				tool_name,
		#"Content": {
			#"Request": 		"create",
			#"TaskID":			task.get_instance_id(),
			#"links":			links_to_create,
		#},
	#}
#)
