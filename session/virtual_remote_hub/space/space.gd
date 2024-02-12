extends Node3D

var config : Dictionary = {
	"name" : ""
}

@onready var hub = get_parent()


func configure(new_config : Dictionary):
	config = new_config
	print("space configuration: ", config)
