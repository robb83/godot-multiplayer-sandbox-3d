extends Node

# 20: Couldn't create an ENet host.

enum NetworkState { NOT_CONNECTED, CONNECTING, CONNECTED, AUTH_FAILED , LISTENING }

signal state_changed
signal peer_connected
signal peer_disconnected
signal disconnected

var current_id : int = -1
var state : NetworkState = NetworkState.NOT_CONNECTED
var original_title = null
var password = null
var crypto : Crypto = Crypto.new()

func _ready():
	multiplayer.server_relay = true
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_authenticating.connect(_authenticating)
	multiplayer.peer_authentication_failed.connect(_authenticating_failed)
	multiplayer.auth_callback = _authenticator
	
func _authenticator(id, data):
	G.trace("_authenticator: %s", id)
	
	if multiplayer.is_server():
		if password:
			if G.compare_auth_message(crypto, current_id, id, password, data):
				multiplayer.complete_auth(id)
				G.trace("authenticate accepted: %s", id)
		else:
			multiplayer.complete_auth(id)
			G.trace("authenticate accepted: %s", id)
			
func _authenticating_failed(id):
	G.trace("_authenticating_failed: %s", id)
	
	if not multiplayer.is_server():
		_set_state(NetworkState.AUTH_FAILED)
		
func _authenticating(id):
	G.trace("_authenticating: %s", id)
	
	if multiplayer.is_server():
		if not password:
			multiplayer.complete_auth(id)
		
	if id == G.SERVER_PEER_ID:
		if password:
			multiplayer.send_auth(id, G.create_auth_message(crypto, id, current_id, password))
			multiplayer.complete_auth(id)
			password = null
			G.trace("authentication sent")
		else:
			multiplayer.complete_auth(id)
	
func network_host(port, pswd):
	var peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, 4)
	if err == OK:
		password = pswd
		multiplayer.set_multiplayer_peer(peer)
		current_id = peer.get_unique_id()
		_set_state(NetworkState.LISTENING)
	else:
		printerr(err)
		_set_state(NetworkState.NOT_CONNECTED)
	return err
	
func network_join(ip, port, pswd):
	password = pswd
	_set_state(NetworkState.CONNECTING)
	
	var peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err == OK:
		multiplayer.set_multiplayer_peer(peer)
		current_id = peer.get_unique_id()
	else:
		printerr(err)
		_set_state(NetworkState.NOT_CONNECTED)
	return err
	
func network_disconnect():
	G.trace("network_disconnect")
	multiplayer.set_multiplayer_peer(null)
	_set_state(NetworkState.NOT_CONNECTED)
	
func network_kick(peer_id):
	multiplayer.get_multiplayer_peer().disconnect_peer(peer_id)

func _peer_connected(id: int) -> void:
	G.trace("_player_connected = %d", id)
	peer_connected.emit(id)

func _peer_disconnected(id: int) -> void:
	G.trace("_player_disconnected = %d", id)
	peer_disconnected.emit(id)

func _on_connected_ok() -> void:
	G.trace("_on_connected_ok")
	_set_state(NetworkState.CONNECTED)
	get_window().title = get_window().title
	
func _on_connected_fail():
	G.trace("_on_connected_fail")
	multiplayer.set_multiplayer_peer(null)
	_set_state(NetworkState.NOT_CONNECTED)
	
func _on_server_disconnected():
	G.trace("_on_server_disconnected")
	_set_state(NetworkState.NOT_CONNECTED)
	disconnected.emit()
	multiplayer.set_multiplayer_peer(null)

func _set_state(s):
	state = s
	state_changed.emit(s)
	
	if state == NetworkState.LISTENING:
		_set_title(" SERVER(%d)" % multiplayer.get_unique_id())
	elif state == NetworkState.CONNECTED:
		_set_title(" CLIENT(%d)" % multiplayer.get_unique_id())
	else:
		_set_title("")

func _set_title(text):
	if not original_title:
		original_title = get_window().title
	get_window().title = original_title + text
