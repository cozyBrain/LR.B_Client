extends Node

@onready var local_hub = get_node("/root/hub")


var virtual_remote_hub # ref for this script
const virtual_remote_hub_dflt_name = "virtual_remote_hub"
var virtual_remote_hub_offline = preload("res://session/virtual_remote_hub/virtual_remote_hub_offline.tscn")
var virtual_remote_hub_online = preload("res://session/virtual_remote_hub/virtual_remote_hub_online.tscn")

var enet := ENetMultiplayerPeer.new()
var space_projection = preload("res://session/hub/space/space_projection.tscn")
var start_menu = preload("res://start_menu/start_menu.tscn")

var connection_buffer : PackedByteArray # buffer to be sent when server connected

func set_up_connection() -> int:
	var err := enet.create_client("127.0.0.1", 7000)
	if err: return err
	err = enet.get_host().dtls_client_setup(
		"dtls_test.com", # common_name of cert. if different, handshake fail!
		TLSOptions.client(
			load("res://cert/dtls_test.crt")
		)
	)
	return err


func _ready():
	# connect signals
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_packet.connect(_on_peer_packet)


func _on_connected_to_server():
	print("connected to the server.")
	send_packet(connection_buffer)

func _on_server_disconnected():
	multiplayer.multiplayer_peer.close()
	print("server disconnected")


func _on_connection_failed():
	OS.alert("connection failed")
	# reset connection_buffer
	connection_buffer = PackedByteArray()

func _on_peer_packet(id: int, packet: PackedByteArray):
	print(id, ": ", packet.get_string_from_ascii())



#region _on_login_and_register_button_pressed
func _on_login_button_pressed() -> void:
	# set up connection
	var err := set_up_connection()
	if err: printerr(error_string(err))
	
	# get ID, PW to login
	var ID : String = (local_hub.get_node("start_menu").get_node("%ID_Input") as LineEdit).get_text()
	var PW : String = (local_hub.get_node("start_menu").get_node("%PW_Input") as LineEdit).get_text()
	var json_string : String = JSON.stringify(
		{
			"Request" : "Login",
			"ID" : ID,
			"PW" : PW
		}
	)
	
	# create connection_buffer
	connection_buffer = json_string.to_utf8_buffer() # json_string to utf8 is recommended.
	# connect to server
	multiplayer.set_multiplayer_peer(enet)

func _on_register_button_pressed() -> void:
	# set up connection
	var err := set_up_connection()
	if err: printerr(error_string(err))
	
	# get ID, PW to register
	var ID : String = (local_hub.get_node("start_menu").get_node("%ID_Input") as LineEdit).get_text()
	var PW : String = (local_hub.get_node("start_menu").get_node("%PW_Input") as LineEdit).get_text()
	var json_string : String = JSON.stringify(
		{
			"Request" : "Register",
			"ID" : ID,
			"PW" : PW
		}
	)
	
	# create connection_buffer
	connection_buffer = json_string.to_utf8_buffer()
	# connect to server
	multiplayer.set_multiplayer_peer(enet)
#endregion


func enter_session(session_config : Dictionary) -> void:
	print(session_config)
	# setup window and capture mouse
	window.scale_with_screen_size_ratio_pivot_x(window.session_window_size_scale)
	window.center()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# queue_free start_menu
	local_hub.get_node("start_menu").queue_free()
	
	if session_config["online"] == true:
		print("<-online->")
		switch_virtual_remote_hub_to_online()
	else:
		print("<-offline->")
		switch_virtual_remote_hub_to_offline()
		
		# set space config in virtual_remote_hub
		virtual_remote_hub.get_node("space").configure(session_config["space_config"])
	
	
	# create space_projection and player
	local_hub.add_child(space_projection.instantiate())



func exit_session() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	local_hub.get_node("space_projection").queue_free()
	# create start_menu again
	local_hub.add_child(start_menu.instantiate())


func send_packet(packet: PackedByteArray) -> void:
	(multiplayer as SceneMultiplayer).send_bytes(packet)

func arr_send_packet(arr: Array) -> void: ## useful function
	pass

func handle(data: Dictionary):
	var selected_hub = data["Hub"]
	selected_hub.handle(data)



# set virtual_remote_hub offline or online
func switch_virtual_remote_hub_to_offline():
	if not virtual_remote_hub == null:
		local_hub.remove_child(virtual_remote_hub)
	var i := virtual_remote_hub_offline.instantiate()
	i.name = virtual_remote_hub_dflt_name
	local_hub.add_child(i)
	virtual_remote_hub = i
func switch_virtual_remote_hub_to_online():
	if not virtual_remote_hub == null:
		local_hub.remove_child(virtual_remote_hub)
	var i := virtual_remote_hub_online.instantiate()
	i.name = virtual_remote_hub_dflt_name
	local_hub.add_child(i)
	virtual_remote_hub = i
func virtual_remote_hub_to_offline():
	var i := virtual_remote_hub_offline.instantiate()
	i.name = virtual_remote_hub_dflt_name
	local_hub.add_child(i)
	virtual_remote_hub = i
