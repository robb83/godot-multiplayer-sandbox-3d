extends Node3D

#@onready var player_template2 = preload("res://huge_mesh.tres")
@onready var player_template = preload("res://objects/player.tscn")
@onready var pickable_01 = preload("res://objects/pickable_03.tscn")
@onready var options: Control = $UI/Options

@onready var player_container: Node3D = $Players
@onready var static_objects: Node3D = $StaticObjects
@onready var dynamic_objects: Node3D = $DynamicObjects
@onready var player_spawner: PlayerSpawner = $PlayerSpawner
@onready var day_night_cycle: DayNightCycle = $DayNightCycle

const SPAWN_RANDOM := 5.0

func _ready():
	G.trace("_ready %s", self.name)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player_spawner.spawn_function = _handle_player_spawn
	
	if multiplayer.is_server():
		for n in static_objects.get_children():
			G.set_synchronizers_add_visibility_filter(n, player_spawner.visibility_filter)
			G.set_synchronizers_public_visibility(n, true)
			
		for n in dynamic_objects.get_children():
			G.set_synchronizers_add_visibility_filter(n, player_spawner.visibility_filter)
			G.set_synchronizers_public_visibility(n, true)
			
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

func _handle_player_spawn(player_peer_id, player_position):	
	G.trace("_handle_player_spawn: %s", str([player_peer_id, player_position]))
	
	var character = player_template.instantiate()
	character.player_peer_id = player_peer_id
	character.name = str(player_peer_id)
	character.position = player_position
	character.set_multiplayer_authority(player_peer_id)
	
	if player_peer_id == multiplayer.get_unique_id():
		G.set_synchronizers_add_visibility_filter(character, player_spawner.visibility_filter)
		G.set_synchronizers_public_visibility(character, true)
	
	return character

func add_player(id: int):
	G.trace("add_player: %s", id)
	var dir := Vector2.from_angle(randf() * 2 * PI)
	var pos := Vector3(dir.x * SPAWN_RANDOM * randf(), 0, dir.y * SPAWN_RANDOM * randf())
	player_spawner.spawn(id, pos)
	
func del_player(id: int):
	var player = player_container.get_node_or_null(str(id))
	if player:
		player.queue_free()

func set_current_player(player : Player):
	G.trace("set_current_player: %s", str(player.player_peer_id) if player else "null")
	
func get_player_by_peer(peer_id):
	return player_container.get_node(str(peer_id)) if player_container.has_node(str(peer_id)) else null
	
@rpc("any_peer", "call_local")
func spawn_object(pos):
	if is_multiplayer_authority():
		var object = pickable_01.instantiate()
		object.position = pos
		G.set_synchronizers_add_visibility_filter(object, player_spawner.visibility_filter)
		G.set_synchronizers_public_visibility(object, true)
		dynamic_objects.add_child(object, true)
