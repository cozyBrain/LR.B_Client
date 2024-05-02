class_name N_Input
extends R_SpaceChunk_obj

const id := &"Input"
static var id_hashed: int = id.hash()


const color := Color.GREEN * 2#(brighter by multiplying color)
const shape_id := &"box"


var in_ports: Dictionary
var out_ports: Dictionary
var output: float

#func project() -> Dictionary:
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
				#N_Something.id:
					#in_ports.push_front(target)
				_:
					return false
		_:
			return false
	return true

## return true if changes have been made.
func disconnect_port(target, port: StringName) -> bool:
	match port:
		node.out_port:
			return out_ports.erase(target)
		node.in_port:
			return in_ports.erase(target)
	return false


#func updateEmissionByOutput() -> void:
	#$CollisionShape/MeshInstance.get_surface_material(0).emission_energy = Output
#

func get_save_data() -> Dictionary:
	return {
		"id": 			id_hashed,
		"in_ports":		in_ports,
		"out_ports":	out_ports,
		"output": 		output,
	}
func load_save_data(save_data: Dictionary) -> N_Input:
	add_initial_change("id", save_data["id"])
	save_data.erase("id")
	for property_name in save_data:
		set(StringName(property_name), save_data[property_name])
		add_initial_change(property_name, save_data[property_name])
	return self
