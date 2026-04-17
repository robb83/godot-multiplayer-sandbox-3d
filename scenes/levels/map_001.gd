extends Node3D

@onready var players: Node3D = $Players
@onready var static_objects: Node3D = $StaticObjects
@onready var dynamic_objects: Node3D = $DynamicObjects
@onready var player_template = preload("res://objects/player.tscn")
@onready var pickable_01 = preload("res://objects/pickable_03.tscn")
@onready var directional_light_3d: DirectionalLight3D = $DirectionalLight3D

const SPAWN_RANDOM := 5.0
const EPSILON = 0.0001

@export var time_of_day := 0.3
@export var day_speed := 0.0025

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$MultiplayerSpawnerPlayers.spawn_function = _handle_player_spawn
	if multiplayer.is_server():
		add_player(1)
		for id in multiplayer.get_peers():
			GameState.current_world.add_player(id)

func _physics_process(delta):
	_handle_sun(delta)

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

func _handle_sun(delta):
	if is_multiplayer_authority():
		var ds = day_speed
		if Input.is_action_pressed("admin_time_speedup"):
			ds = ds * 100
		time_of_day += delta * ds
		time_of_day = fmod(time_of_day, 1)
	
	var offset := TAU * 0.25
	var sun_dir = directional_light_3d.global_transform.basis.z
	
	directional_light_3d.rotation.x = remap( time_of_day * 1440 , 0, 1440, 0 + offset, TAU + offset)
	directional_light_3d.light_color = get_sun_color(sun_dir)
	directional_light_3d.visible = directional_light_3d.rotation.x > TAU * 0.3 + EPSILON and directional_light_3d.rotation.x < TAU * 1.1 - EPSILON
	
func get_sun_color(sun_direction: Vector3) -> Color:
	var elevation = clamp(sun_direction.y, -1.0, 1.0)
	var t = smoothstep(-0.2, 0.6, elevation)   
	t = pow(t, 1.5)
	var sunrise_color = Color(1.0, 0.4, 0.1)
	var noon_color = Color(1.0, 0.95, 0.85)
	var night_color = Color(0.2, 0.3, 0.5)
	if elevation > 0.0:
		return sunrise_color.lerp(noon_color, t)
	else:
		var night_t = smoothstep(-0.4, 0.0, elevation)
		return night_color.lerp(sunrise_color, night_t)
		
func add_player(id: int):
	print("[%s] add_player " % [multiplayer.get_unique_id()])
	var dir := Vector2.from_angle(randf() * 2 * PI)
	var pos := Vector3(dir.x * SPAWN_RANDOM * randf(), 0, dir.y * SPAWN_RANDOM * randf())
	$MultiplayerSpawnerPlayers.spawn([id, pos])
	
func del_player(id: int):
	if not players.has_node(str(id)):
		return
	players.get_node(str(id)).queue_free()
	
func get_player_by_peer(peer_id):
	return players.get_node(str(peer_id)) if players.has_node(str(peer_id)) else null
	
@rpc("any_peer", "call_local")
func spawn_object(pos):
	if is_multiplayer_authority():
		var object = pickable_01.instantiate()
		object.position = pos
		dynamic_objects.add_child(object, true)
