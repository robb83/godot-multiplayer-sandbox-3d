extends Node3D
class_name EndlessChunkManager

# TODO:
# test: unload chunk with remote player on it
# test: remote player chunks keep it on server
# test: authorization transfer to client
# test: disable player synchronization

@onready var chunks: Node3D = $Chunks

@export var chunk_scene: PackedScene
@export var start_scene: PackedScene
@export var chunk_length: float = 50.0
@export var view_distance: int = 5

var player : Player = null
var spawned_chunks = {}
var last_chunk_index : int = 0

func _process(_delta):
	update_chunks()

func update_chunks():
	if not player:
		if GameState.current_world:
			player = GameState.current_world.get_client_player()
			if not player:
				return
		
	var player_z = player.global_transform.origin.z
	var current_chunk = int(player_z / chunk_length)
	
	for i in range(current_chunk, current_chunk + view_distance):
		if not spawned_chunks.has(i):
			_spawn_chunk(i)
			chunk_loaded.rpc(i)
			
	for key in spawned_chunks.keys():
		if key < current_chunk - 2:
			if multiplayer.is_server() and spawned_chunks[key].players.size() > 0:
				return
			spawned_chunks[key].queue_free()
			spawned_chunks.erase(key)
			chunk_removed.rpc(key)

func _spawn_chunk(index):
	var chunk = start_scene.instantiate() if index == 0 else chunk_scene.instantiate()
	chunk.name = str(index)
	chunk.position.z = index * chunk_length
	chunks.add_child(chunk)
	spawned_chunks[index] = chunk

@rpc("any_peer")
func chunk_loaded(chunk):
	var peer_id = multiplayer.get_remote_sender_id()
	print("[%s] chunk_loaded: %s, %s" % [multiplayer.get_unique_id(), chunk, peer_id])
	if spawned_chunks.has(chunk):
		spawned_chunks[chunk].set_synchronizers_visibility_for(multiplayer.get_remote_sender_id(), true)
	
@rpc("any_peer")
func chunk_removed(chunk):
	var peer_id = multiplayer.get_remote_sender_id()
	print("[%s] chunk_removed: %s, %s" % [multiplayer.get_unique_id(), chunk, peer_id])
	if spawned_chunks.has(chunk):
		spawned_chunks[chunk].set_synchronizers_visibility_for(multiplayer.get_remote_sender_id(), false)
