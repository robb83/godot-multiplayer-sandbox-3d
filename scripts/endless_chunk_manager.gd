extends Node3D
class_name EndlessChunkManager

# TODO:
# test: unload chunk with remote player on it
# test: remote player chunks keep it on server
# test: authorization transfer to client
# test: disable player synchronization

# TODO: client error on RPC call for non-visible node
# TODO: dynamic objects removed from client when leave object origin chunk

var chunk01 := preload("res://scenes/levels/endless_chunks/endless_trip_chunk.tscn")
var chunk02 := preload("res://scenes/levels/endless_chunks/endless_trip_chunk_start.tscn")

@onready var chunks: Node3D = $Chunks
@onready var objects: Node3D = $Objects
@onready var multiplayer_spawner_objects: MultiplayerSpawner = $"../MultiplayerSpawnerObjects"

@export var chunk_scene: PackedScene
@export var start_scene: PackedScene
@export var chunk_length: float = 50.0
@export var view_distance: int = 3

var player : Player = null
var spawned_chunks = {}
var last_chunk_index : int = 0
var chunk_states : Dictionary = {}
var object_counter : int = 1
var object_storage : EndlessObjectStorage = null

func _ready():
	Network.player_disconnected.connect(_player_disconnected)
	multiplayer_spawner_objects.spawn_function = _spawn_object_function
	object_storage = EndlessObjectStorage.new(chunk_length)
	
func _player_disconnected(peer_id):
	for key in spawned_chunks.keys():
		var instance = spawned_chunks[key]
		if instance.players.has(peer_id):
			instance.set_synchronizers_visibility_for(peer_id, false)
	
func _spawn_object_function(data):
	var id = data[0]
	var scene = data[1]
	var pos = data[2]
	var rot = data[3]
	var chunk = get_chunk_index(pos.z)
	#print("[%s] _spawn_function %s" % [multiplayer.get_unique_id(), str(data)])
	
	var object = load(scene).instantiate()
	object.name = str(id)
	object.position = pos
	object.rotation = rot
	
	#TODO: refactor/rethink (just for quick test)
	GameState.set_synchronizers_public_visibility(object, false)
	if multiplayer.is_server():
		if spawned_chunks.has(chunk):
			for p in spawned_chunks[chunk].players.keys():
				GameState.set_synchronizers_visibility_for(object, p, true)
	
	return object

func get_chunk_index(z_pos: float) -> int:
	return int(floor(z_pos / chunk_length))

func spawn_dynamic_object(scene_path, pos, rot):
	#print("[%s] spawn_dynamics_object %s, %s" % [multiplayer.get_unique_id(), str(scene_path), pos])
	
	#TODO: object type id
	
	object_counter = object_counter + 1
	var id = object_counter
	
	object_storage.update_object(id, scene_path, pos, rot)
	multiplayer_spawner_objects.spawn([id, scene_path, pos, rot])
	
func _process(_delta):
	_update_chunks()

func _update_chunks():
	if not player:
		if GameState.current_world:
			player = GameState.current_world.get_client_player()
			if not player:
				return
	
	var current_chunk = get_chunk_index(player.global_transform.origin.z)
	
	for i in range(max(0, current_chunk - view_distance), current_chunk + view_distance):
		
		if i < 0: continue
			
		if not spawned_chunks.has(i):
			_spawn_chunk(i)
		else:
			spawned_chunks[i].visible = true
			
	for key in spawned_chunks.keys():
		if key < current_chunk - view_distance or key > current_chunk + view_distance:
			if multiplayer.is_server() and spawned_chunks[key].players.size() > 0:
				spawned_chunks[key].visible = false
				continue
				
			_remove_chunk(key)

func _remove_chunk(index):
	print("[%s] _remove_chunk: %s" % [multiplayer.get_unique_id(), index])
	
	_remove_objects(index)
	
	spawned_chunks[index].queue_free()
	spawned_chunks.erase(index)
	if not multiplayer.is_server():
		chunk_removed.rpc_id(1, index)

func _remove_objects(index):
	if multiplayer.is_server():
		var pos = spawned_chunks[index].position
		chunk_states[index] = spawned_chunks[index].get_chunk_state()
		
		# update before remove
		var items = object_storage.get_objects(pos.z, 0)
		for i in items:
			var id = str(i.id)
			if objects.has_node(id):
				var node = objects.get_node(id)
				object_storage.update_object(i.id, i.scene, node.position, node.rotation)
		
		# remove
		items = object_storage.get_objects(pos.z, 0)
		for i in items:
			var id = str(i.id)
			if objects.has_node(id):
				var node = objects.get_node(id)
				object_storage.update_object(i.id, i.scene, node.position, node.rotation)
				node.freeze = true
				node.queue_free()

func _spawn_chunk(index):
	print("[%s] _spawn_chunk: %s" % [multiplayer.get_unique_id(), index])
	
	var chunk = start_scene.instantiate() if index == 0 else chunk_scene.instantiate()
	chunk.name = str(index)
	chunk.index = index
	chunk.position.z = (chunk_length / 2.0) + (index * chunk_length)
	chunk.manager = self
	spawned_chunks[index] = chunk
	
	chunks.add_child(chunk)
	
	if multiplayer.is_server():
		if chunk_states.has(index):
			chunk.set_chunk_state(chunk_states[index])
			_spawn_objects(index)
		else:
			chunk.generate()
	else:
		chunk_loaded.rpc_id(1, index)
	
func _spawn_objects(index):
	if multiplayer.is_server():
		if spawned_chunks.has(index):
			print("[%s] spawn_objects: %s" % [multiplayer.get_unique_id(), str(index)])
			var pos = spawned_chunks[index].position.z
			var items = object_storage.get_objects(pos, 0)
			for i in items:
				var id = str(i.id)
				if not objects.has_node(id):
					multiplayer_spawner_objects.spawn([i.id, i.scene, i.pos, i.rot])
				else:
					print("Already spawned: %s" % id)

@rpc("any_peer")
func chunk_loaded(chunk):
	if not multiplayer.is_server():
		return
		
	var peer_id = multiplayer.get_remote_sender_id()
	print("[%s] chunk_loaded: %s, %s" % [multiplayer.get_unique_id(), peer_id, chunk])
	
	if not spawned_chunks.has(chunk):
		_spawn_chunk(chunk)
		
	#TODO: refactor (just for quick test)
	if spawned_chunks.has(chunk):
		var instance = spawned_chunks[chunk]
		instance.set_synchronizers_visibility_for(peer_id, true)
		var ps = instance.players.keys()
		var items = object_storage.get_objects(instance.position.z, 0)
		for i in items:
			for p in ps:
				if objects.has_node(str(i.id)):
					GameState.set_synchronizers_visibility_for(objects.get_node(str(i.id)), p, true)
	
@rpc("any_peer")
func chunk_removed(chunk):
	if not multiplayer.is_server():
		return
		
	var peer_id = multiplayer.get_remote_sender_id()
	print("[%s] chunk_removed: %s, %s" % [multiplayer.get_unique_id(), peer_id, chunk])
	
	if spawned_chunks.has(chunk):
		var instance = spawned_chunks[chunk]
		instance.set_synchronizers_visibility_for(peer_id, false)
		
		#TODO: refactor (just for quick test)
		var ps = instance.players.keys()
		var items = object_storage.get_objects(instance.position.z, 0)
		for i in items:
			for p in ps:
				if objects.has_node(str(i.id)):
					GameState.set_synchronizers_visibility_for(objects.get_node(str(i.id)), p, false)
