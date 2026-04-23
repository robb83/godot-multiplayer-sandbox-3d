extends Node

var selected_world = null
var current_world : Node = null
var menu_visible : bool = false
var peers_connected = {}
var peers_ready : Dictionary = {}
var peer_player_spawned : Dictionary = {}

func _ready():
	Network.peer_connected.connect(_peer_connected)
	Network.peer_disconnected.connect(_peer_disconnected)
	Network.state_changed.connect(_state_changed)

func _state_changed(state):
	if state == Network.NetworkState.NOT_CONNECTED:
		reset()
	
func _peer_connected(id):
	peers_connected[id] = true
	peers_ready[id] = false
	
func _peer_disconnected(id):
	peers_connected.erase(id)
	peers_ready.erase(id)
	peer_player_spawned.erase(id)
	if multiplayer.is_server() and current_world:
		current_world.del_player(id)

func reset():
	peers_connected = {}
	peers_ready = {}
	peer_player_spawned = {}
	if current_world:
		#TODO: how to remove without multiplayer error
		current_world.set_process_mode(Node.PROCESS_MODE_DISABLED)
		current_world.queue_free()
		current_world = null

func client_ready():
	if multiplayer.is_server():
		peers_ready[G.SERVER_PEER_ID] = true
		if current_world:
			for pid in peers_ready.keys():
				if peers_ready[pid]:
					current_world.add_player(pid)
	else:
		client_ready_remote.rpc_id(G.SERVER_PEER_ID)

@rpc("any_peer")
func client_ready_remote():
	G.trace("client_ready %s", multiplayer.get_remote_sender_id())
	if multiplayer.is_server():
		var peer_id = multiplayer.get_remote_sender_id()
		peers_ready[peer_id] = true
		if peers_ready.get(G.SERVER_PEER_ID, false) == true and current_world:
			current_world.add_player(peer_id)

func get_worlds() -> Array:
	var result = []
	var resources = ResourceLoader.list_directory("res://scenes/levels")
	for r in resources:
		if r.ends_with(".tscn"):
			result.append({ "name": r.get_basename(), "path": "res://scenes/levels/" + r })
	return result
