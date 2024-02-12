class_name N_ReLU
extends Chunk_obj

const id := &"ReLU"
static var id_hashed: int = id.hash()


const color := Color.GREEN * 2#(brighter by multiplying color)
const shape_id := &"box"


var in_ports: Dictionary

var out_ports: Dictionary
var output: float

var b_output: float
var leakage: float = .1


#func project():
	#return {
		#"id": id_hashed,
		#"output": output,
	#}


## return true if changes have been made.
func connect_port(target, port: StringName) -> bool:
	match port:
		node.out_port:
			match target.get("id"):
				N_ReLU.id:
					out_ports[target] = null
				_:
					return false
		node.in_port:
			match target.get("id"):
				N_ReLU.id, N_Input.id:
					in_ports[target] = float(0) # Each port has its own weight.
				_:
					return false
		_:
			return false
	parent_chunk.queue_projection_update()
	parent_chunk.enable_save_on_unload()
	return true


## return true if changes have been made.
func disconnect_port(target, port: StringName) -> bool:
	var ret := false
	match port:
		node.out_port:
			ret = out_ports.erase(target)
		node.in_port:
			ret = in_ports.erase(target)
	if ret:
		parent_chunk.queue_projection_update()
		parent_chunk.enable_save_on_unload()
	return ret


func prop() -> void:
	var sum: float = 0
	for n in in_ports:
		sum += n.get_output()
	output = activation_func(sum)
	add_change("output", output)

func b_prop() -> void:
	var sum: float = 0
	for n in out_ports:
		sum += n.get_b_output()
	b_output = sum * derivate_activation_func(output)

func update_weights(): ## TODO: need update
	for i in in_ports.size():
		pass
		#weights[i] -= in_ports[i].output * b_output


func activation_func(x: float) -> float:
	if x < 0:
		return x * leakage
	return x
func derivate_activation_func(x: float) -> float:
	if x < 0:
		return leakage
	return 1.0


#func updateEmissionByOutput() -> void:
	#$CollisionShape/MeshInstance.get_surface_material(0).emission_energy = Output
#

func get_save_data() -> Dictionary:
	return {
		"id": 			id_hashed,
		"in_ports":		in_ports,
		"out_ports":	out_ports,
		"output": 		output,
		"b_output": 	b_output,
		"leakage":		leakage,
	}
func load_save_data(save_data:Dictionary) -> N_ReLU:
	add_initial_change("id", save_data["id"])
	save_data.erase("id")
	for property_name in save_data:
		set(StringName(property_name), save_data[property_name])
		add_initial_change(property_name, save_data[property_name])
	return self

