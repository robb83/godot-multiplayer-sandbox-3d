extends Node
class_name PlayerInput

@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

@export var jumping := false
@export var running := false
@export var crouching := false
@export var direction := Vector2()
@export var hold_distance : float = 8.0
@export var player : Player = null
@export var orientation : Vector2 = Vector2.ZERO
@export var object_rotation : Vector2 = Vector2.ZERO

var mouse_sensitivity : float = 0.01
var pitch_min : float = deg_to_rad(-70)
var pitch_max : float = deg_to_rad(70)
var min_hold_distance : float = 1.5
var max_hold_distance : float = 8.0
var scroll_speed : float = 0.5
var rotating_object : bool = false

func _ready():
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_physics_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_process_input(get_multiplayer_authority() == multiplayer.get_unique_id())
	multiplayer_synchronizer.add_visibility_filter(func(id): return id == 1)
	
@rpc("any_peer", "call_local", "reliable")
func jump():
	jumping = true
	
func _input(event):
	if GameState.menu_visible:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			rotating_object = event.pressed
			
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			hold_distance = clamp(hold_distance + scroll_speed, min_hold_distance, max_hold_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			hold_distance = clamp(hold_distance - scroll_speed, min_hold_distance, max_hold_distance)
		
	if event is InputEventMouseMotion:
		if rotating_object:
			#object_rotation.y = wrapf(object_rotation.y + -event.relative.x * mouse_sensitivity, -PI, PI)
			#object_rotation.x = wrapf(object_rotation.x + -event.relative.y * mouse_sensitivity, -PI, PI)
			object_rotation.y = object_rotation.y + -event.relative.x * mouse_sensitivity
			object_rotation.x = object_rotation.x + -event.relative.y * mouse_sensitivity
		else:
			orientation.y = wrapf(orientation.y + -event.relative.x * mouse_sensitivity, -PI, PI)
			orientation.x = clamp(orientation.x - event.relative.y * mouse_sensitivity, pitch_min, pitch_max)

func _physics_process(_delta: float) -> void:
	if GameState.menu_visible:
		return
		
	direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	running = Input.is_action_pressed("move_run")
	crouching = Input.is_action_pressed("move_crouch")
	
	if Input.is_action_just_pressed("move_jump"):
		_handle_jump()
		
	if Input.is_action_just_pressed("interact_secondary"):
		_handle_secondary_interaction()
		
	if Input.is_action_just_pressed("interact"):
		_handle_primary_interaction()
		
	_handle_interaction_visual_feedback()
	
func _handle_jump():
	jumping = true # local
	jump.rpc_id(1) # server
	
func _handle_secondary_interaction():
	if player.held_object:
		print(player.held_object)
		if is_instance_valid(player.held_object):
			player.held_object.drop.rpc_id(1)
		else:
			player.held_object = null
	else:
		var pos = player.camera.global_transform.origin + -player.camera.global_transform.basis.z * 5
		player.current_map.spawn_object.rpc_id(1, pos)
	
func _handle_primary_interaction():
	var result = player.ray_cast_interaction.get_collider()
	if result:
		var collider = result
		var collision_point = player.ray_cast_interaction.get_collision_point()
		if collider.is_in_group("interactable"):
			var object = collider.get_meta("object")
			object.interact.rpc_id(1)
		if collider.is_in_group("driveable"):
			var object = collider.get_meta("object")
			object.drive(self)
		elif collider.is_in_group("pickable"):
			var object = collider.get_meta("object")
			object_rotation = Vector2.ZERO
			hold_distance = clamp(collider.global_position.distance_to(player.global_position), min_hold_distance, max_hold_distance)
			object.pickup.rpc_id(1, object.to_local(collision_point))

func _handle_interaction_visual_feedback():
	var msi = player.mouse_state_indicator
	if msi:
		var result = player.ray_cast_interaction.get_collider()
		if result:
			var collider = result
			if collider.is_in_group("interactable"):
				msi.set_state(1)
				return
			elif collider.is_in_group("driveable"):
				msi.set_state(3)
				return
			elif collider.is_in_group("pickable"):
				msi.set_state(2)
				return
		msi.set_state(0)
