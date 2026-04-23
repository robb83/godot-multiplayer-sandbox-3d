extends Node
class_name PlayerSpawner

@export var player_container : Node = null

var spawn_function : Callable
var client_peer_id : int = -1
	
func spawn(peer_id, pos):
	var node = spawn_function.call(peer_id, pos)
	player_container.add_child(node, true)

func visibility_filter(id : int):
	return id != 0 and GameState.peers_connected.get(id, false) and GameState.peer_player_spawned.get(id, false)
	
func _ready():
	client_peer_id = multiplayer.get_unique_id()
	player_container.child_entered_tree.connect(_player_added)
	player_container.child_exiting_tree.connect(_player_removed)
	
func _player_added(node : Node):
	var peer_id = node.player_peer_id
	
	if multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		
		# broadcast new players to clients
		for n in player_container.get_children():
			var np = n.player_peer_id
			if np != peer_id and np != client_peer_id:
				player_spawn.rpc_id(np, peer_id, node.position)
		
		# broadcast existing players to new client
		if peer_id != client_peer_id:
			for n in player_container.get_children():
				var np = n.player_peer_id
				player_spawn.rpc_id(peer_id, np, n.position)
	
	GameState.peer_player_spawned[peer_id] = true
	if peer_id == client_peer_id and GameState.current_world:
		GameState.current_world.set_current_player(node)

func _player_removed(node : Node):
	var removed_peer_id = node.player_peer_id
	
	if  multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		for n in player_container.get_children():
			var nma = n.player_peer_id
			if removed_peer_id != nma and nma != client_peer_id:
				player_despawn.rpc_id(nma, removed_peer_id)
	
	GameState.peer_player_spawned.erase(removed_peer_id)
	if removed_peer_id == client_peer_id and GameState.current_world:
		GameState.current_world.set_current_player(null)
	
@rpc("authority")
func player_spawn(peer_id, pos):
	G.trace("player_spawn: %s", peer_id)
	var node = spawn_function.call(peer_id, pos)
	if player_container.get_node_or_null(str(peer_id)):
		G.trace("player_spawn: already exists (%s, %s)", node.name, peer_id)
	player_container.add_child(node, true)

@rpc("authority")
func player_despawn(peer_id):
	G.trace("player_despawn: %s", peer_id)
	var node = player_container.get_node_or_null(str(peer_id))
	if node:
		node.queue_free()
