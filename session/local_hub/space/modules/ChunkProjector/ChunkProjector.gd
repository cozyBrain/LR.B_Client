class_name SpaceChunkProjector
extends Node3D

const CHUNK_LAYER = 0b00000000_00000000_00000000_00000010 ## collision_layer and mask for chunk detection.

const module_name = &"ChunkProjector"

static var chunk_size = R_SpaceChunk.chunk_size ## TODO: Update

var chunks: Dictionary # {pos: chunk}

@onready var link_projector := %space_modules/LinkProjector as SpaceLinkProjector

@onready var chunk_item = preload("res://session/local_hub/space/modules/ChunkProjector/ChunkProjectorChunkItem.tscn")

@onready var intobject_pre_allocation_tick := $intobject_pre_allocation_tick as Timer
var intobject_pre_allocation_tick_interval := 0.05 # in seconds

var thread_project_changes := Thread.new()
var thread_project_links := Thread.new()


func _init():
	# Safely set invisible_chunk_radius 
	invisible_chunk_radius = visible_chunk_radius + 2


func _ready():
	# Setup intobject_pool of ChunkProjectorChunkItem.
	ChunkProjectorChunkItem.intobject_pool.intobject_space_sample = R_SpaceChunk.build_intobject_sample(chunk_size)
	ChunkProjectorChunkItem.intobject_pool.max_pre_allocation = 600
	ChunkProjectorChunkItem.intobject_pool.max_allocation_per_call = 30
	ChunkProjectorChunkItem.intobject_pool.fully_pre_allocate()
	intobject_pre_allocation_tick.start(intobject_pre_allocation_tick_interval)
	intobject_pre_allocation_tick.timeout.connect(ChunkProjectorChunkItem.intobject_pool.pre_allocate)

func handle(v: Dictionary):   
	match StringName(v.get("Request")):
		&"observe_chunk":
			var chunk_pos = v.get("pos")
			chunk_pos = Vector3i(chunk_pos[0], chunk_pos[1], chunk_pos[2])
			var chunk_update = v.get("chunk")
			if not len(chunk_update) < 4:
				chunk_update = bytes_to_var(v.get("chunk"))
				if chunk_update == null:
					return
				var chunk = chunks.get(chunk_pos) as ChunkProjectorChunkItem
				if chunk == null:
					chunk = chunk_item.instantiate()
					chunks[chunk_pos] = chunk
					chunk.position = chunk_pos * chunk_size
					chunk.setup_intobject_array()
					add_child(chunk)
					chunk.rescale(chunk_size)
				
				var intobject_changes = chunk_update.get("intobject")
				if intobject_changes != null:
					chunk.intobject_changes = intobject_changes
					chunk.link_pointer_changes = chunk_update.get("link_pointer", {})
					if thread_project_changes.is_started():
						thread_project_changes.wait_to_finish()
					thread_project_changes.start(chunk.project_changes)
				
				var link_pointer_changes = chunk_update.get("link_pointer")
				if link_pointer_changes != null:
					link_projector.project(link_pointer_changes)
					


func _exit_tree():
	if thread_project_changes.is_started():
		thread_project_changes.wait_to_finish()
	if thread_project_links.is_started():
		thread_project_links.wait_to_finish()


func free_chunk(chunk_pos: Vector3i):
	var chunk = chunks.get(chunk_pos) as ChunkProjectorChunkItem
	if chunk != null:
		# Get links to decrement observation count.
		var links_to_decrement := chunk.get_registered_link_pointer()
		for link_id in links_to_decrement.keys():
			link_projector.decrement_link_observation_count(link_id)
		
		chunk.return_res()
		remove_child(chunk)
		chunks.erase(chunk_pos)

func _on_chunks_detector_detected(area):
	var detected_area_pos = Vector3i(area.get_node("..").position / chunk_size)
	var detected_area: ChunkProjectorChunkItem = chunks.get(detected_area_pos)
	# activate collision
	detected_area.activate_collision()

func _on_chunks_detector_detected_exit(area):
	var detected_area_pos = Vector3i(area.get_node("..").position / chunk_size)
	var detected_area: ChunkProjectorChunkItem = chunks.get(detected_area_pos)
	# deactivate collision
	detected_area.deactivate_collision()

var max_visible_chunk_range := 64
var visible_chunk_radius : int = 8 # unit: chunk.
var invisible_chunk_radius : int: # must be bigger than visible_chunk_radius.
	set(v):
		invisible_chunk_radius = clampi(v, visible_chunk_radius + 1, v)
	get:
		return invisible_chunk_radius
var safe_margin := 2 # additional bigger boundary to call unobserve() while player moving fast. must be bigger than 1.

var current_chunk_pos : Vector3i
var previous_chunk_pos : Vector3i

# prevent from requesting same observation for optimization
var previous_visible_chunks : Dictionary # {pos...}
var previous_invisible_chunks : Dictionary # {pos...}

func update_visible_range(player_position : Vector3, spawn := false):
	current_chunk_pos = R_SpaceChunk.global_pos_to_chunk_pos(player_position, chunk_size)
	# if player migrate.
	if current_chunk_pos != previous_chunk_pos or spawn: # force update if spawn is true
		var boundary := invisible_chunk_radius+safe_margin
		var prev_invisible_chunks := {}
		for x in range(current_chunk_pos.x-boundary, current_chunk_pos.x+boundary+1):
			for y in range(current_chunk_pos.y-boundary, current_chunk_pos.y+boundary+1):
				for z in range(current_chunk_pos.z-boundary, current_chunk_pos.z+boundary+1):
					var distance = Vector3(current_chunk_pos.x, current_chunk_pos.y, current_chunk_pos.z).distance_to(Vector3(x,y,z))
					var chunk_pos := Vector3i(x,y,z)
					if distance <= visible_chunk_radius:
						if previous_visible_chunks.has(chunk_pos): # Prevent meaningless observe request.
							continue
						%player.chunk_observer.observe(chunk_pos, self, false)
						previous_visible_chunks[chunk_pos] = null
					elif distance >= invisible_chunk_radius:
						if previous_visible_chunks.has(chunk_pos): # Only previously observe queued.
							%player.chunk_observer.unobserve(chunk_pos, self, false)
							prev_invisible_chunks[chunk_pos] = null
							free_chunk(chunk_pos) ## TODO: Consider Links. chunk_observer is for this problem.
							
		%player.chunk_observer.flush()
		
		for pos in prev_invisible_chunks.keys():
			# Unblock to observe the unobserve_queued_chunk.
			previous_visible_chunks.erase(pos)
		
		print("current_chunk_pos: ", current_chunk_pos)
		#<DEPRECATED>
		#print(
			#"current_chunk_pos: ", current_chunk_pos,\
			#"  loaded_chunks: ", space_module_chunk.get_total_loaded_chunks(),\
			#"  observation_queue: ",space_module_chunk.observation_queue.size(),\
			#"  unload_queue: ", space_module_chunk.unload_queue.size(),
			#"  pool: ", space_module_chunk.chunk_item.intobject_pool.intobject_spaces.size()
		#)
		
		previous_chunk_pos = current_chunk_pos
