extends Node


func _ready():
	pass

func handle(data: Dictionary):
	print("virtual_remote_hub_online:", data)
	terminal.send_packet(var_to_bytes(data))
