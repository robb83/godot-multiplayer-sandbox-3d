extends Node

# 20: Couldn't create an ENet host.

enum NetworkState { NOT_CONNECTED, CONNECTING, CONNECTED , LISTENING }

signal state_changed
signal peer_connected
signal peer_disconnected
signal disconnected

var current_id : int = -1
var state : NetworkState = NetworkState.NOT_CONNECTED
var original_title = null

func _ready():
	multiplayer.server_relay = true
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
func network_host(port):
	var peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, 4)
	if err == OK:
		multiplayer.set_multiplayer_peer(peer)
		current_id = peer.get_unique_id()
		_set_state(NetworkState.LISTENING)
	else:
		printerr(err)
		_set_state(NetworkState.NOT_CONNECTED)
	return err
	
func network_join(ip, port):
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
	print("[%s] network_disconnect" % [current_id])
	multiplayer.set_multiplayer_peer(null)
	_set_state(NetworkState.NOT_CONNECTED)
	
func network_kick(peer_id):
	multiplayer.get_multiplayer_peer().disconnect_peer(peer_id)

func _peer_connected(id: int) -> void:
	print("[%s] _player_connected = %d" % [current_id, id])
	peer_connected.emit(id)

func _peer_disconnected(id: int) -> void:
	print("[%s] _player_disconnected = %d" % [current_id, id])
	peer_disconnected.emit(id)

func _on_connected_ok() -> void:
	print("[%s] _on_connected_ok" % [current_id])
	_set_state(NetworkState.CONNECTED)
	get_window().title = get_window().title
	
func _on_connected_fail():
	print("[%s] _on_connected_fail" % [current_id])
	multiplayer.set_multiplayer_peer(null)
	_set_state(NetworkState.NOT_CONNECTED)
	
func _on_server_disconnected():
	print("[%s] _on_server_disconnected" % [current_id])
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
