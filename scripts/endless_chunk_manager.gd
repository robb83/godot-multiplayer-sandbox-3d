extends Node3D
class_name EndlessChunkManager

# TODO:
# test: unload chunk with remote player on it
# test: remote player chunks keep it on server
# test: authorization transfer to client
# test: disable player synchronization

@onready var chunks: Node3D = $Chunks
@onready var objects: Node3D = $Objects
@onready var multiplayer_spawner_objects: MultiplayerSpawner = $"../MultiplayerSpawnerObjects"

@export var chunk_scene: PackedScene
@export var start_scene: PackedScene
@export var chunk_length: float = 50.0
@export var view_distance: int = 5

var player : Player = null
var spawned_chunks = {}
var last_chunk_index : int = 0
var chunk_states : Dictionary = {}
var object_counter : int = 0

func _ready():
	multiplayer_spawner_objects.spawn_function = _spawn_function
	
func _spawn_function(data):
	var id = data[0]
	var scene = data[1]
	var pos = data[2]
	
	var object = load(scene).instantiate()
	object.name = str(name)
	object.position = pos
	return object
	
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
	
	for i in range(current_chunk - view_distance, current_chunk + view_distance):
		if i < 0:
			continue
			
		if not spawned_chunks.has(i):
			_spawn_chunk(i)
			chunk_loaded.rpc(i)
			
	for key in spawned_chunks.keys():
		if key < current_chunk - view_distance:
			if multiplayer.is_server() and spawned_chunks[key].players.size() > 0:
				continue
			_remove_chunk(key)

func spawn_dynamics_object(scene_path, pos):
	print("[%s] spawn_dynamics_object %s, %s" % [multiplayer.get_unique_id(), str(scene_path), pos])
	
	#TODO: object type id
	
	object_counter = object_counter + 1
	var id = object_counter
	
	multiplayer_spawner_objects.spawn([id, scene_path, pos])
	
func _remove_chunk(index):
	if multiplayer.is_server():
		chunk_states[index] = spawned_chunks[index].get_chunk_state()
	spawned_chunks[index].queue_free()
	spawned_chunks.erase(index)
	chunk_removed.rpc(index)

func _spawn_chunk(index):
	var chunk = start_scene.instantiate() if index == 0 else chunk_scene.instantiate()
	chunk.name = str(index)
	chunk.position.z = index * chunk_length
	chunk.manager = self
	chunks.add_child(chunk)
	spawned_chunks[index] = chunk
	
	if multiplayer.is_server():
		if chunk_states.has(index):
			chunk.set_chunk_state(chunk_states[index])
		else:
			chunk.generate()
	
@rpc("any_peer")
func request_chunk_state(chunk):
	if multiplayer.is_server():
		var peer_id = multiplayer.get_remote_sender_id()
		if spawned_chunks.has(chunk):
			response_chunk_state.rpc_id(peer_id, chunk, spawned_chunks[chunk].get_chunk_state())
		elif spawned_chunks.has(chunk):
			response_chunk_state.rpc_id(peer_id, chunk, chunk_states[chunk])
		else:
			print("ERROR")
		
@rpc("authority")
func response_chunk_state(chunk, state):
	chunk_states[chunk] = state
	if spawned_chunks.has(chunk):
		spawned_chunks[chunk].set_chunk_state(state)
		
@rpc("any_peer")
func chunk_loaded(chunk):
	var peer_id = multiplayer.get_remote_sender_id()
	print("[%s] chunk_loaded: %s, %s" % [multiplayer.get_unique_id(), peer_id, chunk])
	
	if multiplayer.is_server():
		if not spawned_chunks.has(chunk):
			_spawn_chunk(chunk)
		
	if spawned_chunks.has(chunk):
		spawned_chunks[chunk].set_synchronizers_visibility_for(peer_id, true)
	
@rpc("any_peer")
func chunk_removed(chunk):
	var peer_id = multiplayer.get_remote_sender_id()
	print("[%s] chunk_removed: %s, %s" % [multiplayer.get_unique_id(), peer_id, chunk])
	
	if spawned_chunks.has(chunk):
		spawned_chunks[chunk].set_synchronizers_visibility_for(peer_id, false)
		if multiplayer.is_server() and spawned_chunks[chunk].players.size() == 0:
			_remove_chunk(chunk)
