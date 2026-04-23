extends Node

const SERVER_PEER_ID : int = 1
const SHARED_SECRET : String = "GodotMultiplayerSandbox3D"

const COLORS = [
	Color("#E53935"), Color("#1E88E5"), Color("#43A047"), 
	Color("#8E24AA"), Color("#212121"), Color("#FAFAFA") 
]

func trace(message : String, ...args:Array):
	var header = "[%s] " % multiplayer.get_unique_id()
	print(header, message % args)
	
func set_synchronizers_visibility_for(root: Node, peer_id : int, value: bool) -> void:
	if !is_instance_valid(root):
		return

	if root is MultiplayerSynchronizer:
		root.set_visibility_for(peer_id, value)
		
	for child in root.get_children():
		set_synchronizers_visibility_for(child, peer_id, value)

func set_synchronizers_public_visibility(root: Node, value: bool) -> void:
	if !is_instance_valid(root):
		return
	
	if root is MultiplayerSynchronizer:
		root.public_visibility = value
		
	for child in root.get_children():
		set_synchronizers_public_visibility(child, value)
		
func set_synchronizers_add_visibility_filter(root: Node, filter: Callable) -> void:
	if !is_instance_valid(root):
		return
	
	if root is MultiplayerSynchronizer:
		root.add_visibility_filter(filter)
		
	for child in root.get_children():
		set_synchronizers_add_visibility_filter(child, filter)
		
func set_synchronizers_remove_visibility_filter(root: Node, filter: Callable) -> void:
	if !is_instance_valid(root):
		return
	
	if root is MultiplayerSynchronizer:
		root.remove_visibility_filter(filter)
		
	for child in root.get_children():
		set_synchronizers_remove_visibility_filter(child, filter)

func create_auth_message(crypto:Crypto, server_id : int, client_id : int, password : String):
	var key = (str(server_id) + str(client_id) + password).to_ascii_buffer()
	var message = (G.SHARED_SECRET + str(client_id)).to_ascii_buffer()
	return crypto.hmac_digest(HashingContext.HASH_SHA256, message, key)
	
func compare_auth_message(crypto:Crypto, server_id : int, client_id : int, password : String, received : PackedByteArray):
	return crypto.constant_time_compare(create_auth_message(crypto, server_id, client_id, password), received)
