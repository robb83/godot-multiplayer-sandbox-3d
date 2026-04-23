extends Node3D
class_name EndlessChunkManager

# TODO:
# test: unload chunk with remote player on it
# test: remote player chunks keep it on server
# test: authorization transfer to client
# test: disable player synchronization

# TODO: Client has an error when receive RPC call from non-visible node
# TODO: _update_objects batch
# TODO: object view distance need to be less than chunk view distance
# TODO: freeze object

var chunk01 := preload("res://scenes/levels/endless_chunks/endless_trip_chunk.tscn")
var chunk02 := preload("res://scenes/levels/endless_chunks/endless_trip_chunk_start.tscn")

@onready var chunk_container: Node3D = $Chunks
@onready var object_container: Node3D = $Objects
@onready var multiplayer_spawner_objects: MultiplayerSpawner = $"../MultiplayerSpawnerObjects"

@export var chunk_scene: PackedScene
@export var start_scene: PackedScene
@export var chunk_length: float = 50.0
@export var view_distance: int = 3

var player : Player = null
var spawned_chunks = {}
var chunk_objects : Dictionary = {}
var chunk_players : Dictionary = {}
var chunk_states : Dictionary = {}
var object_counter : int = 1
var object_storage : EndlessObjectStorage = null
var object_players : Dictionary = {}
var objects_chunk : Dictionary = {}
var local_peer_id = 1

func get_chunk_index(z_pos: float) -> int:
	return int(floor(z_pos / chunk_length))

func _ready():
	local_peer_id = multiplayer.get_unique_id()
	Network.peer_disconnected.connect(_peer_disconnected)
	multiplayer_spawner_objects.spawn_function = _spawn_object_function
	object_storage = EndlessObjectStorage.new(chunk_length)
	
	if multiplayer.is_server():
		object_container.child_exiting_tree.connect(_object_exiting)
		object_container.child_entered_tree.connect(_object_entered)

func _object_visiblity_filter(peer : int, object_id : int) -> bool:
	if object_players.has(object_id):
		return object_players[object_id].get(peer, false)
	return false
	
func _object_entered(node : Node):
	#G.trace("_object_entered = %s", node.name)
	var object_id = int(node.name)
	var chunk_index = get_chunk_index(node.position.z)
	
	objects_chunk[object_id] = chunk_index
	chunk_objects.get_or_add(chunk_index, {})[object_id] = true
	
	if chunk_players.has(chunk_index):
		for peer_id in chunk_players[chunk_index].keys():
			if chunk_players[chunk_index][peer_id]:
				object_players.get_or_add(object_id, {})[peer_id] = true
				if peer_id == local_peer_id:
					node.visible = true

func _object_exiting(node : Node):
	#G.trace("_object_exiting = %s", node.name)
	var object_id = int(node.name)
	var chunk_index = objects_chunk.get(object_id, -1)
	if chunk_objects.has(chunk_index):
		chunk_objects[chunk_index].erase(object_id)
	objects_chunk.erase(object_id)
	object_storage.update_object(object_id, node.scene_file_path, node.position, node.rotation)
	object_players.erase(object_id)
	
func _peer_disconnected(peer_id):
	for key in chunk_players.keys():
		chunk_players[key].erase(peer_id)
	
func _spawn_object_function(data):
	var id = data[0]
	var scene = data[1]
	var pos = data[2]
	var rot = data[3]
	
	#G.trace("_spawn_function %s", str(data))
	
	var object = load(scene).instantiate()
	object.name = str(id)
	object.position = pos
	object.rotation = rot
	
	object.visible = not multiplayer.is_server()

	G.set_synchronizers_add_visibility_filter(object, Callable(self, "_object_visiblity_filter").bind(id))
	G.set_synchronizers_public_visibility(object, true)
	
	return object

func spawn_dynamic_object(scene_path, pos, rot):
	#G.trace("spawn_dynamics_object %s, %s", str(scene_path), pos)
	
	#TODO: object type id
	
	object_counter = object_counter + 1
	var id = object_counter
	
	object_storage.update_object(id, scene_path, pos, rot)
	multiplayer_spawner_objects.spawn([id, scene_path, pos, rot])
	
func set_player(p:Player):
	player = p
	
func _process(_delta):
	_update_chunks()
	_update_objects(_delta)
	
func _update_objects(_delta):
	if not multiplayer.is_server():
		return
		
	for node in object_container.get_children():
		var object_id = int(node.name)
		var chunk_index = get_chunk_index(node.position.z)
		var visible_players = object_players.get_or_add(object_id, {})
		var players_in_chunk = chunk_players.get(chunk_index)
		var previous_object_chunk = objects_chunk.get(object_id, -1)
		var still_visible = {}
		
		if previous_object_chunk != chunk_index:
			chunk_objects[previous_object_chunk].erase(object_id)
			objects_chunk[object_id] = chunk_index
			chunk_objects.get_or_add(chunk_index, {})[object_id] = true
		
		if players_in_chunk:
			for peer_id in players_in_chunk.keys():
				if players_in_chunk[peer_id]:
					if visible_players.has(peer_id):
						still_visible[peer_id] = true
					else:
						visible_players[peer_id] = true
						still_visible[peer_id] = true
						if peer_id == local_peer_id:
							node.visible = true

		for peer_id in visible_players.keys():
			if not still_visible.has(peer_id):
				visible_players.erase(peer_id)
				if peer_id == local_peer_id:
					node.visible = false
					
		if visible_players.size() == 0:
			node.queue_free()
		
func _update_chunks():
	if not player:
		return
	
	var current_chunk = get_chunk_index(player.global_transform.origin.z)
	
	for i in range(max(0, current_chunk - view_distance), current_chunk + view_distance):
		
		if i < 0: continue
			
		if not spawned_chunks.has(i):
			_set_chunk_visiblity_for(local_peer_id, i, true)
			_spawn_chunk(i)
		else:
			spawned_chunks[i].visible = true
			_set_chunk_visiblity_for(local_peer_id, i, true)
			
	for key in spawned_chunks.keys():
		if key < current_chunk - view_distance or key > current_chunk + view_distance:
			_set_chunk_visiblity_for(local_peer_id, key, false)
			spawned_chunks[key].visible = false
			
			if multiplayer.is_server():
				if has_player(key) or has_object(key):
					continue
			elif has_object(key):
				continue
				
			_remove_chunk(key)

func _remove_chunk(index):
	G.trace("_remove_chunk: %s", index)
	
	_unload_object_from_chunk(index)
	
	chunk_states[index] = spawned_chunks[index].get_chunk_state()
	spawned_chunks[index].queue_free()
	spawned_chunks.erase(index)
	if not multiplayer.is_server():
		chunk_removed.rpc_id(G.SERVER_PEER_ID, index)

func _spawn_chunk(index):
	G.trace("_spawn_chunk: %s", index)
	
	var chunk = start_scene.instantiate() if index == 0 else chunk_scene.instantiate()
	chunk.name = str(index)
	chunk.index = index
	chunk.position.z = (chunk_length / 2.0) + (index * chunk_length)
	chunk.manager = self
	spawned_chunks[index] = chunk
	
	G.set_synchronizers_add_visibility_filter(chunk, Callable(self, "_chunk_visibility_filter").bind(index))
	G.set_synchronizers_public_visibility(chunk, true)
	
	chunk_container.add_child(chunk)
	
	if multiplayer.is_server():
		if chunk_states.has(index):
			chunk.set_chunk_state(chunk_states[index])
			_load_object_from_storage(index)
		else:
			chunk.generate()
	else:
		chunk_loaded.rpc_id(G.SERVER_PEER_ID, index)
	
@rpc("any_peer")
func chunk_loaded(chunk):
	var peer_id = multiplayer.get_remote_sender_id()
	
	if not multiplayer.is_server():
		return
		
	G.trace("chunk_loaded: %s, %s", peer_id, chunk)
		
	if not spawned_chunks.has(chunk):
		_spawn_chunk(chunk)
		
	_set_chunk_visiblity_for(peer_id, chunk, true)
	
@rpc("any_peer")
func chunk_removed(chunk):
	if not multiplayer.is_server():
		return
		
	var peer_id = multiplayer.get_remote_sender_id()
	G.trace("chunk_removed: %s, %s", peer_id, chunk)
	
	_set_chunk_visiblity_for(peer_id, chunk, false)
		
	#TODO: notify object visibility change if needed

func has_player(chunk_index) -> bool:
	return chunk_players.has(chunk_index) and chunk_players[chunk_index].size() > 0

func has_object(chunk_index) -> bool:
	return chunk_objects.has(chunk_index) and chunk_objects[chunk_index].size() > 0
	
func _set_chunk_visiblity_for(peer_id:int, chunk_index:int, value:bool):
	if value:
		var players = chunk_players.get_or_add(chunk_index, {})
		players[peer_id] = value
	else:
		if chunk_players.has(chunk_index):
			chunk_players[chunk_index].erase(peer_id)

func _unload_object_from_chunk(_index):
	#G.trace("_unload_object_from_chunk: %s", index)
	pass

func _load_object_from_storage(index):
	G.trace("_load_object_from_storage: %s", index)
	var items = object_storage.get_objects(index * chunk_length, 0)
	for i in items:
		var id = str(i.id)
		if not object_container.has_node(id):
			multiplayer_spawner_objects.spawn([i.id, i.scene, i.pos, i.rot])

func _chunk_visibility_filter(peer : int, index : int) -> bool:
	if peer == G.SERVER_PEER_ID: return true
	return chunk_players.has(index) and chunk_players[index].get(peer, false)
