class_name R_SpaceChunk
extends Node
## Client side chunks are updated by handle_observation_queue() and ChunkItem.broadcast_chunk_update().
## Obj(intobject&flobject) in chunk can call the ChunkItem's function. usually they call enable_save_on_unload(), queue_projection_update().
## also they can use Chunk(this script) functions.


static var chunk_size := 32
var number_of_partitions := 2
var partition: Array[Dictionary] # [dict{chunks...}, dict{chunks...}...]


class ChunkItem:
	enum {INTOBJECT, FLOBJECT, LINK_POINTER, OBJ_TYPES}
	static var intobject_pool: intobject_space_pool
	static var broadcast_chunk_update_tick: Timer ## Connected to self.broadcast_chunk_update() when there's observer.
	var chunk_pos: Vector3i ## Set by R_SpaceChunk.set_chunk(pos, new_chunk).
	var _intobject: Array # [][][] 3D
	var _flobject: Array  ## about to be octree
	var _link_pointer: Dictionary ## link_pointer[start, end, channel]
	var link_pointer_change_set: Dictionary
	var observers: Dictionary # {player...}
	
	var projection_snapshot: Array ## Merged with projection changes to update snapshot when project_changes() is called. This is for new observer.
	var projection_changes: PackedByteArray ## Updated when is_projection_update_pending.
	var compressed_projection_snapshot: PackedByteArray ## Updated when is_compressed_snapshot_update_pending.
	var is_compressed_snapshot_update_pending := false ## Prevent meaningless var_to_bytes() call.
	
	## Objs in the chunk can call queue_projection_update() so that the chunk get changes from the objects.
	var is_projection_update_pending := false ## True if any projection needs an update.
	var is_intobject_projection_update_pending := false
	var is_flobject_projection_update_pending := false
	var is_link_pointer_projection_update_pending := false

	var save_data: Dictionary ## Holds some resources for a moment to be returned by return_res().
	var save_on_unload := false ## Objs can call enable_save_on_unload() to set this true.
	
	func _init() -> void:
		# init projection_sapshot.
		projection_snapshot.resize(OBJ_TYPES)
		projection_snapshot.fill([])
		
	func return_res() -> void: ## before free, return_res() for performance and to disconnect signals.
		# Return save_data["_intobject"].
		var intobject_save_data = save_data.get("_intobject", [])
		if not intobject_save_data.is_empty():
			intobject_pool.return_res(intobject_save_data)
		# Return _intobject.
		if not _intobject.is_empty():
			intobject_pool.return_res(_intobject)
		# Return projection_snapshot.
		if not projection_snapshot.is_empty():
			if not projection_snapshot[INTOBJECT].is_empty():
				intobject_pool.return_res(projection_snapshot[INTOBJECT])
		# Disconnect signals
		if broadcast_chunk_update_tick.timeout.is_connected(broadcast_chunk_update):
			broadcast_chunk_update_tick.timeout.disconnect(broadcast_chunk_update)
	func load_save_data(data: Dictionary) -> ChunkItem: ## TODO: _flobject loading
		# Load intobject.
		_intobject = intobject_pool.borrow_res()
		var intobject_snapshot = intobject_pool.borrow_res()
		var intobject_save_data = data["_intobject"]
		for x in intobject_save_data.size():
			for y in intobject_save_data[x].size():
				for z in intobject_save_data[x][y].size():
					var obj_save_data = intobject_save_data[x][y][z]
					if obj_save_data != null:
						var obj_id = obj_save_data.get("id")
						var obj: R_SpaceChunk_obj = node.scripts[obj_id].new().load_save_data(obj_save_data)
						insert_intobject(Vector3i(x,y,z), obj, true)
						intobject_snapshot[x][y][z] = obj.project_changes()
		projection_snapshot[INTOBJECT] = intobject_snapshot
		#projection_snapshot[Flobject] = flobject_snapshot
		
		# Load link_pointer.
		var link_pointer_save_data := data.get(["_link_pointer"], {}) as Dictionary
		if link_pointer_save_data.is_empty():
			projection_snapshot[LINK_POINTER] = Dictionary()
		else:
			for link_id in link_pointer_save_data.keys():
				# save_data = {[spoint, epoint] : false}
				insert_link_pointer(link_id)
		
		# Create compressed_snapshot after loading intobject & flobject.
		is_compressed_snapshot_update_pending = true
		project_snapshot()
		# Unregister loaded things from the dictionary, data.
		data.erase("_intobject")
		data.erase("_flobject")
		# Set up the rest
		for property in data.keys():
			set(property, data[property])
		return self
	func get_save_data() -> Dictionary:
		var intobject_save_data := intobject_pool.borrow_res()
		for x in _intobject.size():
			for y in _intobject[x].size():
				for z in _intobject[x][y].size():
					var obj = _intobject[x][y][z]
					if not obj == null:
						intobject_save_data[x][y][z] = obj.get_save_data()
		var flobject_save_data := Array()
		for obj in _flobject:
			flobject_save_data.append(obj.get_save_data())
		save_data = {
			"_intobject"	: intobject_save_data,
			"_flobject"		: flobject_save_data,
			"_link_pointer"	: _link_pointer, # _link_pointer[link_id] = false, link_id = [spoint, epoint]
		}
		return save_data
	func enable_save_on_unload(enable := true):
		save_on_unload = enable
	
	func insert_intobject(pos: Vector3i, obj, initial := false) -> bool:
		if _intobject.is_empty():
			# Setup intobject space and snapshot for the intobject.
			_intobject = intobject_pool.borrow_res()
			projection_snapshot[INTOBJECT] = intobject_pool.borrow_res()
		# Let obj access to parent_chunk.
		obj.parent_chunk = self
		obj.queue_projection_update = queue_intobject_projection_update
		_intobject[pos.x][pos.y][pos.z] = obj
		if not initial:
			queue_intobject_projection_update()
			enable_save_on_unload()
		return true
	func get_intobject(pos: Vector3i) -> Object:
		if not _intobject.is_empty():
			return _intobject[pos.x][pos.y][pos.z]
		return null
	
	func insert_link_pointer(link_pointer: Array):
		_link_pointer[link_pointer] = false # _link_pointer[spoint, epoint] = false
		link_pointer_change_set[link_pointer] = false
		queue_link_pointer_projection_update()
		enable_save_on_unload()
	func remove_link_pointer(link_pointer: Array, channel: int):
		if _link_pointer.erase(link_pointer):
			link_pointer_change_set[link_pointer] = null
			queue_link_pointer_projection_update()
			enable_save_on_unload()
	
	func observe(o) -> void:
		observers[o] = null
		# if there's observer, connect to the signal, broadcast_chunk_update_tick.
		if not observers.is_empty():
			if not broadcast_chunk_update_tick.timeout.is_connected(broadcast_chunk_update):
				broadcast_chunk_update_tick.timeout.connect(broadcast_chunk_update)
		if o.has_method("_on_chunk_observed"):
			o._on_chunk_observed(self)
	
	func unobserve(o) -> bool: ## Return true when there's no observer.
		observers.erase(o)
		# if there's no observers, disconnect to the signal, broadcast_chunk_update_tick.
		if observers.is_empty():
			broadcast_chunk_update_tick.timeout.disconnect(broadcast_chunk_update)
			return true
		return false
	
	func project_snapshot() -> PackedByteArray: ## Update compressed_projection_snapshot.
		if is_compressed_snapshot_update_pending: # if pending, update compressed_projection_snapshot.
			is_compressed_snapshot_update_pending = false
			# Create latest compressed_projection_snapshot with projection_snapshot.
			compressed_projection_snapshot = var_to_bytes(
				{
					"intobject"	:	projection_snapshot[INTOBJECT],
					#"flobject"	:	projection_snapshot[FLOBJECT],
					"link_pointer":	projection_snapshot[LINK_POINTER],
				}
			)
			compressed_projection_snapshot = compress_projection(compressed_projection_snapshot)
		return compressed_projection_snapshot
	## Update projection_changes and projection_snapshot.
	func project_changes() -> PackedByteArray: 
		var updates := {}
		# if pending, update projection_changes and projection_snapshot.
		if is_intobject_projection_update_pending:
			is_intobject_projection_update_pending = false
			var intobject_projection = intobject_pool.borrow_res()
			intobject_pool.return_res_deffered(intobject_projection)
			updates["intobject"] = project_intobject_changes(intobject_projection)
		if is_link_pointer_projection_update_pending:
			is_link_pointer_projection_update_pending = false
			updates["link_pointer"] = project_link_pointer_changes()
		if not updates.is_empty():
			# Create latest projection_changes.
			projection_changes = var_to_bytes(updates)
		return projection_changes
	
	## Set projection_update_pending and compressed_snapshot_update_pending true.
	func queue_projection_update_all():
		is_intobject_projection_update_pending = true
		is_flobject_projection_update_pending = true
		is_link_pointer_projection_update_pending = true
		is_compressed_snapshot_update_pending = true
	func queue_intobject_projection_update():
		is_intobject_projection_update_pending = true
		is_compressed_snapshot_update_pending = true
	func queue_flobject_projection_update():
		is_flobject_projection_update_pending = true
		is_compressed_snapshot_update_pending = true
	func queue_link_pointer_projection_update():
		is_link_pointer_projection_update_pending = true
		is_compressed_snapshot_update_pending = true
	
	
	## intobject_projection[x][y][z] == false, means there's no changes.
	## intobject_projection[x][y][z] == null, means the space is empty.
	func project_intobject_changes(intobject_projection: Array) -> Array:
		for x in _intobject.size():
			for y in _intobject[x].size():
				for z in _intobject[x][y].size():
					var obj = _intobject[x][y][z]
					match obj:
						null:
							# if it's null, set null.
							intobject_projection[x][y][z] = obj
							# Update snapshot.
							projection_snapshot[INTOBJECT][x][y][z] = obj
						_: # don't change "_:" to "Chunk_obj:".
							var changes: Dictionary = obj.project_changes()
							if changes.is_empty():
								intobject_projection[x][y][z] = false
							else:
								intobject_projection[x][y][z] = changes
								# Update snapshot.
								if projection_snapshot[INTOBJECT][x][y][z] == null:
									# if it was empty, reset with Dictionary.
									projection_snapshot[INTOBJECT][x][y][z] = Dictionary()
								projection_snapshot[INTOBJECT][x][y][z].merge(changes, true) # Update projection snapshot by merging changes.
		return intobject_projection
	func project_flobject_changes() -> Array:
		var flobject_projection := []
		for obj in _flobject:
			match obj:
				null:
					pass
				R_SpaceChunk_obj:
					flobject_projection.append(obj.project_changes())
		return flobject_projection
	func project_link_pointer_changes() -> Dictionary:
		for changed_link in link_pointer_change_set.keys():
			var channel_changes = link_pointer_change_set[changed_link]
			# Update snapshot.
			if channel_changes == null: # if it's removed with remove_link_pointer().
				projection_snapshot.erase(changed_link)
			else:
				projection_snapshot[changed_link] = channel_changes # can be complicated like projection_snapshot[INTOBJECT][x][y][z].merge(changes, true)
		var link_pointer_projection := link_pointer_change_set.duplicate(true)
		link_pointer_change_set.clear()
		return link_pointer_projection
	
	func broadcast_chunk_update() -> void: ## Called by broadcast_chunk_update_tick signal.
		if is_link_pointer_projection_update_pending or is_intobject_projection_update_pending or is_flobject_projection_update_pending:
			var changes := project_changes()
			var compressed_changes = compress_projection(changes)
			for observer in observers:
				if observer.has_method("_on_chunk_changes_observed"):
					observer._on_chunk_changes_observed(self, compressed_changes)
	
	func compress_projection(chunk):
		return chunk


@onready var intobject_pre_allocation_tick := $intobject_pre_allocation_tick as Timer
var intobject_pre_allocation_tick_interval := 0.05 # in seconds

class intobject_space_pool:
	var intobject_space_sample: Array
	var intobject_spaces: Array ## pre_allocated spaces.
	var max_pre_allocation: int
	var max_allocation_per_call: int
	
	func fully_pre_allocate() -> void:
		var remains_to_max_alloc := (max_pre_allocation - intobject_spaces.size())
		for i in remains_to_max_alloc:
			intobject_spaces.push_back(intobject_space_sample.duplicate(true))
	
	func pre_allocate() -> void:
		var remains_to_max_alloc := (max_pre_allocation - intobject_spaces.size())
		# if it's over the max_pre_allocation, resize.
		if remains_to_max_alloc < 0:
			intobject_spaces.resize(max_pre_allocation)
			return
		var amount_to_alloc = clamp(remains_to_max_alloc, 0, max_allocation_per_call)
		for i in amount_to_alloc:
			intobject_spaces.push_back(intobject_space_sample.duplicate(true))
		
	func borrow_res() -> Array:
		if intobject_spaces.is_empty():
			return intobject_space_sample.duplicate(true)
		return intobject_spaces.pop_back()
	func return_res(res: Array):
		# if pre_allocation is already full, return.
		if max_pre_allocation <= intobject_spaces.size():
			return
		# Reset res
		for i in res.size():
			for j in res.size():
				res[i][j].fill(null)
		intobject_spaces.append(res)
	func return_res_deffered(res: Array):
		call_deferred("return_res", res)


# consider batch processing for get&insert_intobject().
#func get_intobject(global_pos: Vector3i) -> bool:
	#var chunk_pos := R_SpaceChunk.global_pos_to_chunk_pos(global_pos, chunk_size)
	#var chunk = get_chunk(chunk_pos)
	#if chunk != null:
		#return chunk.get_intobject(R_SpaceChunk.global_pos_to_local_intobject_pos(global_pos, chunk_size))
	#prints("get_intobject ignored! failed to get chunk:", chunk_pos)
	#return false

## Return true if the intobject inserted.
func insert_intobject(global_pos: Vector3i, obj) -> bool:
	var chunk_pos := R_SpaceChunk.global_pos_to_chunk_pos(global_pos, chunk_size)
	var chunk = get_chunk(chunk_pos)
	if chunk != null:
		return chunk.insert_intobject(R_SpaceChunk.global_pos_to_local_intobject_pos(global_pos, chunk_size), obj)
	prints("insert_intobject ignored! failed to get chunk:", chunk_pos)
	return false

#region queue_variables and queue_handling
enum {Observe, Unobserve} ## command for observation_queue
var observation_queue: Array ## [[Unobserve, pos, observer]...]
@onready var observation_queue_handle_tick := $observation_queue_handle_tick as Timer
var observation_queue_handle_tick_interval := 0.01 # in seconds
var observation_queue_process_per_tick := 30
var observation_queue_threshold := 100000 # if observation_queue_size() > x, increase queue_process_per_tick temporally

func handle_observation_queue():
	if observation_queue.size() > 0:
		# set buffer_size to process.
		var buffer_size := observation_queue_process_per_tick
		if observation_queue.size() > observation_queue_threshold:
			buffer_size += observation_queue.size() - observation_queue_threshold
		# process queue.
		var buffer = observation_queue.slice(0, buffer_size)
		observation_queue = observation_queue.slice(buffer_size)
		for queue in buffer:
			var pos = queue[1]
			var observer = queue[2]
			if queue[0] == Observe: # if command of the queue is Observe.
				observe(pos, observer)
			else:
				unobserve(pos, observer)


var unload_queue: Array[Vector3i] ## [pos1, pos2...]
@onready var unload_queue_handle_tick := $unload_queue_handle_tick as Timer
var unload_queue_handle_tick_interval := 0.5 # in seconds
var unload_queue_process_per_tick := 100
var unload_queue_threshold := 2000 # If unload_chunk_queue.size() > x, increase queue_process_per_tick temporally

func handle_unload_queue() -> int:
	if unload_queue.size() > 0:
		# set buffer_size to process.
		var buffer_size := unload_queue_process_per_tick
		if unload_queue.size() > unload_queue_threshold:
			buffer_size += unload_queue.size() - unload_queue_threshold
		# proces queue.
		var buffer = unload_queue.slice(0, buffer_size)
		unload_queue = unload_queue.slice(buffer_size)
		for chunk_pos in buffer:
			unload_chunk(chunk_pos)
	return unload_queue.size()


@onready var broadcast_chunk_update_tick := $broadcast_chunk_update_tick as Timer
var broadcast_chunk_update_tick_interval := 0.03 ## about 30 times per second


#endregion



func init():
	# Build partition.
	for i in number_of_partitions:
		partition.append({})
	
	# Setup ChunkItem's static variables.
	# Setup intobject_space_pool.
	var pool := intobject_space_pool.new()
	pool.intobject_space_sample = R_SpaceChunk.build_intobject_sample(chunk_size)
	pool.max_pre_allocation = 1500
	pool.max_allocation_per_call = 40
	pool.fully_pre_allocate()
	ChunkItem.intobject_pool = pool
	ChunkItem.broadcast_chunk_update_tick = broadcast_chunk_update_tick
	# Setup Chunk_obj's static variables.
	R_SpaceChunk_obj.chunk_space = self # Let objs access to chunk_space.
	
	# Start ticks #
	observation_queue_handle_tick.timeout.connect(handle_observation_queue)
	observation_queue_handle_tick.start(observation_queue_handle_tick_interval)
	
	unload_queue_handle_tick.timeout.connect(handle_unload_queue)
	unload_queue_handle_tick.start(unload_queue_handle_tick_interval)
	
	broadcast_chunk_update_tick.start(broadcast_chunk_update_tick_interval) # going to be connected to the chunks that have observer.
	
	intobject_pre_allocation_tick.timeout.connect(ChunkItem.intobject_pool.pre_allocate)
	intobject_pre_allocation_tick.start(intobject_pre_allocation_tick_interval)
	
	print("Chunk ticks are started.")

func pause():
	observation_queue_handle_tick.stop()
	unload_queue_handle_tick.stop()
	broadcast_chunk_update_tick.stop()
	intobject_pre_allocation_tick.stop()

func get_total_loaded_chunks() -> int:
	var total_chunks := 0
	for part in partition:
		total_chunks += part.size()
	return total_chunks

#region observe_unobserve
# The pos must be chunk_pos not global_pos.
func queue_observe(pos: Vector3i, observer):
	observation_queue.append([Observe, pos, observer])

func queue_unobserve(pos: Vector3i, observer):
	observation_queue.append([Unobserve, pos, observer])

func queue_observe_or_unobserve(o: int, pos: Vector3i, observer):
	observation_queue.append([o, pos, observer])

## chunk.observe() must be called after set_chunk().
func observe(pos : Vector3i, observer) -> ChunkItem:
	var chunk = get_chunk(pos)
	if chunk == null: # if not loaded, load.
		chunk = directory.load_chunk(pos)
		if not chunk == null: # if the chunk is loaded succesfully.
			#print("loaded pos: ", pos)
			set_chunk(pos, chunk)
			chunk.observe(observer)
			return chunk
		else: # if the chunk file doesn't exist, create new chunk.
			chunk = ChunkItem.new() as ChunkItem
			set_chunk(pos, chunk)
			chunk.observe(observer)
			return chunk
	else: # if already loaded, just register observer to the chunk.
		chunk.observe(observer)
		return chunk


func unobserve(pos: Vector3i, observer):
	var chunk = get_chunk(pos)
	if chunk != null:
		if chunk.unobserve(observer): # if chunk has no observer, queue unload.
			queue_unload(pos)
		return true 
	return false # return false if the chunk is not loaded.
#endregion

#region unload
func queue_unload(pos: Vector3i):
	# queue chunk to unload
	unload_queue.append(pos)

func unload_chunk(chunk_pos: Vector3i):
	var chunk = get_chunk(chunk_pos) as ChunkItem
	if chunk == null:
		return
	if not chunk.observers.is_empty():
		return
	if chunk.save_on_unload:
		# Save the chunk.
		select_partition_from_chunk_pos(chunk_pos).erase(chunk_pos)
		directory.save_chunk(chunk, chunk_pos)
		chunk.return_res()
	else:
		# Don't save the chunk.
		select_partition_from_chunk_pos(chunk_pos).erase(chunk_pos)
		chunk.return_res()
#endregion

func unload_all_chunks():
	# queue_unload() every chunk
	for part in partition:
		for chunk_pos in part:
			var chunk := get_chunk(chunk_pos)
			chunk.observers = {}
			queue_unload(chunk_pos)
	while handle_unload_queue() > 0:
		pass

func set_chunk(pos: Vector3i, new_chunk: ChunkItem):
	new_chunk.chunk_pos = pos # Set chunk_pos of the new_chunk.
	select_partition_from_chunk_pos(pos)[pos] = new_chunk

func get_chunk(pos: Vector3i) -> ChunkItem:
	return select_partition_from_chunk_pos(pos).get(pos)

func select_partition_from_chunk_pos(chunk_pos: Vector3i) -> Dictionary:
	return partition[abs((chunk_pos.x+chunk_pos.y+chunk_pos.z) % partition.size())]

static func build_intobject_sample(size: int) -> Array:
	var sample := []
	for i in size:
			sample.append([])
			for j in size:
				sample[i].append([])
				sample[i][j].resize(size)
	return sample

static func global_pos_to_chunk_pos(global_pos: Vector3, _chunk_size: int) -> Vector3i:
	return floor(global_pos / float(_chunk_size))

static func global_pos_to_local_intobject_pos(global_pos: Vector3i, _chunk_size: int) -> Vector3i:
	# edit global_pos and return
	if global_pos.x < 0:
		global_pos.x = (_chunk_size - 1) - abs(global_pos.x+1) % _chunk_size
	else:
		global_pos.x = (global_pos.x % _chunk_size)
	
	if global_pos.y < 0:
		global_pos.y = (_chunk_size - 1) - abs(global_pos.y+1) % _chunk_size
	else:
		global_pos.y = (global_pos.y % _chunk_size)
	
	if global_pos.z < 0:
		global_pos.z = (_chunk_size - 1) - abs(global_pos.z+1) % _chunk_size
	else:
		global_pos.z = (global_pos.z % _chunk_size)
	
	return Vector3i(global_pos.x, global_pos.y, global_pos.z)
