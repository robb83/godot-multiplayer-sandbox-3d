extends Node3D

@onready var options: Control = $UI/Options
@onready var player_spawner: PlayerSpawner = $PlayerSpawner
@onready var chunk_manager: EndlessChunkManager = $ChunkManager
@onready var players: Node3D = $ChunkManager/Players
@onready var day_night_cycle: DayNightCycle = $DayNightCycle

@onready var player_template = preload("res://objects/player.tscn")
#@onready var player_template2 = preload("res://huge_mesh.tres")

const SPAWN_POINT := Vector3(0, 0.5, 20)
const SPAWN_RANDOM := 3.0

func _ready():
	G.trace("_ready %s", self.name)
	player_spawner.spawn_function = _handle_player_spawn
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if multiplayer.is_server():
		if day_night_cycle:
			G.set_synchronizers_add_visibility_filter(day_night_cycle, player_spawner.visibility_filter)
			G.set_synchronizers_public_visibility(day_night_cycle, true)
			
	GameState.client_ready()

func _enter_tree() -> void:
	GameState.current_world = self
	
func _exit_tree() -> void:
	GameState.current_world = null

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("menu"):
		options.visible = not options.visible
		GameState.menu_visible = options.visible
		
		if options.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
func _handle_player_spawn(player_peer_id, player_position, player_skin):
	G.trace("_handle_player_spawn: %s %s", player_peer_id, player_position)
	
	var character = player_template.instantiate()
	character.player_peer_id = player_peer_id
	character.name = str(player_peer_id)
	character.position = player_position
	character.player_skin = player_skin
	character.set_multiplayer_authority(player_peer_id)
	
	if player_peer_id == multiplayer.get_unique_id():
		G.set_synchronizers_add_visibility_filter(character, player_spawner.visibility_filter)
		G.set_synchronizers_public_visibility(character, true)
		
	return character

func add_player(id: int):
	G.trace("add_player %s", id)
	var dir := Vector2.from_angle(randf() * 2 * PI)
	var pos := SPAWN_POINT + Vector3(dir.x, 0.0, dir.y) * SPAWN_RANDOM
	player_spawner.spawn(id, pos, id % G.COLORS.size())
	
func del_player(id: int):
	if not players.has_node(str(id)):
		return
	players.get_node(str(id)).queue_free()
	
func set_current_player(player : Player):
	G.trace("set_current_player: %s", str(player.player_peer_id) if player else "null")
	chunk_manager.set_player(player)
	
func get_player_by_peer(peer_id):
	return players.get_node(str(peer_id)) if players.has_node(str(peer_id)) else null
	
@rpc("any_peer", "call_local")
func spawn_object(pos):
	if is_multiplayer_authority():
		chunk_manager.spawn_dynamic_object("res://objects/pickable_03.tscn", pos, Vector3.ZERO)
