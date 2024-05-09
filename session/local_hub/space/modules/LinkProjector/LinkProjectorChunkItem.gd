class_name LinkProjectorChunkItem # chunk item that renders links.
extends Node3D

@onready var triLink = preload("res://session/virtual_remote_hub/space/objects/shapes/triLink/mesh.tres")

var links: Dictionary = {}
var linkPainter: LinkPainter

func _init():
	linkPainter = LinkPainter.new()
	linkPainter.init(triLink)

func _ready():
	add_child(linkPainter)


func increment_link_observation_count(link_id: Array):
	print("link_id:", link_id)
	if links.get(link_id) == null: # New link data.
		links[link_id] = 1
		linkPainter.add_instance(link_id, SpaceLinkProjector.align_link_and_get_transform(link_id[0], link_id[1]), Color(255,255,255))
	else: # if the link is already rendered.
		links[link_id] += 1

func erase_link(link_id: Array):
	links.erase(link_id)
	linkPainter.remove_instance(link_id)


class LinkPainter extends MultiMeshInstance3D:
	## A dictionary that maps link IDs to the indexes of MultiMesh instances.
	var link_to_instance := {}
	var instance_to_link := {}
	var instance_count := 0 ## Number of instances.
	
	## Set mesh.
	func init(m: Mesh):
		var mm := MultiMesh.new()
		mm.mesh = m
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.set_use_colors(true)
		multimesh = mm
	
	func add_instance(link_id: Array, trans: Transform3D, color: Color):
		var instance_id = instance_count
		instance_count += 1
		multimesh.instance_count = instance_count
	
		multimesh.set_instance_transform(instance_id, trans)
		multimesh.set_instance_color(instance_id, color)
	
		# Mapping link_id and instance_index.
		link_to_instance[link_id] = instance_id
		instance_to_link[instance_id] = link_id
		print("add_instance: ", link_id, trans)
		return instance_id
	
	func update_instance(link_id: Array, trans: Transform3D, color: Color):
		var instance_id = link_to_instance[link_id]
		if instance_id == null:
			return
		multimesh.set_instance_transform(instance_id, trans)
		multimesh.set_instance_color(instance_id, color)
	
	func remove_instance(link_id):
		var instance_id = link_to_instance[link_id]
		if instance_id == null:
			return
		
		var last_instance_id = instance_count - 1
		
		# Swap
		swap_instances(instance_id, last_instance_id)
		## Update mapping.
		link_to_instance[find_link_by_instance(last_instance_id)] = instance_id # E(link_id) = 3 # 5->3
		instance_to_link[instance_id] = link_to_instance[find_link_by_instance(last_instance_id)] # 3 = E(link_id) # C->E
	
		link_to_instance.erase(link_id)
		instance_to_link.erase(last_instance_id)
		instance_count -= 1
		multimesh.instance_count = instance_count
	
	func swap_instances(instance_id, last_instance_id):
		var last_instance_transform = multimesh.get_instance_transform(last_instance_id)
		var last_instance_color = multimesh.get_instance_color(last_instance_id)
		multimesh.set_instance_transform(instance_id, last_instance_transform)
		multimesh.set_instance_color(instance_id, last_instance_color)
	
	func find_link_by_instance(instance_id: int):
		return instance_to_link.get(instance_id)
	func find_instance_by_link(link_id: Array):
		return link_to_instance.get(link_id)
	
	func clear():
		multimesh.instance_count = 0
		instance_count = 0
		link_to_instance.clear()
		instance_to_link.clear()


#Algorithm: Efficiently remove specific instances from the mapping between MultiMesh instances and links.
#<0> Want to remove C(instance_id = 3)
#1 2 3 4 5, these are multimesh instance idx.
#A B C D E, these are link_id.
#1 2 3 4 5, these are elements of the instance_to_link.
#link_to_instance[E] -> 5
#instance_to_link[5] -> E
#
#<1> Swap C and E(last)
#1 2 3 4 5
#A B E D C
#1 2 5 4 3
#link_to_instance[E] -> 5
#instance_to_link[5] -> E
#
#<2> Update mapping
#1 2 3 4 5
#A B E D C
#1 2 3 4 3
#link_to_instance[E] -> 3
#instance_to_link[3] -> E
#
#<3> Erase C -> link_to_instance.erase(link_id), instance_to_link.erase(last_instance_id)
#1 2 3 4 5
#A B E D
#1 2 3 4
#
#<4> instance_count - 1.
#1 2 3 4
#A B E D
#1 2 3 4
