extends Node3D

@onready var chunk_manager: EndlessChunkManager = $ChunkManager
@onready var players: Node3D = $ChunkManager/Players

@onready var player_template = preload("res://objects/player.tscn")
@onready var pickable_01 = preload("res://objects/pickable_03.tscn")

const SPAWN_POINT := Vector3(0, 0.5, 7)
const SPAWN_RANDOM := 2.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$MultiplayerSpawnerPlayers.spawn_function = _handle_player_spawn
	if multiplayer.is_server():
		add_player(1)
		for id in multiplayer.get_peers():
			add_player(id)

func _enter_tree() -> void:
	GameState.current_world = self
	
func _exit_tree() -> void:
	GameState.current_world = null

func _handle_player_spawn(data):
	print("[%s] _handle_player_spawn: %s" % [multiplayer.get_unique_id(), str(data)])
	
	var player_peer_id = data[0]
	var player_position = data[1]
	
	var character = player_template.instantiate()
	character.player_peer_id = player_peer_id
	character.name = str(player_peer_id)
	character.position = player_position
	return character

func add_player(id: int):
	print("[%s] add_player " % [multiplayer.get_unique_id()])
	var dir := Vector2.from_angle(randf() * 2 * PI)
	var pos := SPAWN_POINT + Vector3(dir.x, 0.0, dir.y) * SPAWN_RANDOM
	$MultiplayerSpawnerPlayers.spawn([id, pos])
	
func del_player(id: int):
	if not players.has_node(str(id)):
		return
	players.get_node(str(id)).queue_free()
	
func get_player_by_peer(peer_id):
	return players.get_node(str(peer_id)) if players.has_node(str(peer_id)) else null
	
func get_client_player():
	return get_player_by_peer(multiplayer.get_unique_id())
	
@rpc("any_peer", "call_local")
func spawn_object(pos):
	if is_multiplayer_authority():
		var object = pickable_01.instantiate()
		object.position = pos
		add_child(object, true)
