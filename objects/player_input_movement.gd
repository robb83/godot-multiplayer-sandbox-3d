extends Node
class_name PlayerInputMovement

@export var player : Player = null
@export var jumping := false
@export var running := false
@export var crouching := false
@export var direction := Vector2()
@export var orientation : Vector2 = Vector2.ZERO
@export var object_distance : float = 8.0
@export var object_rotation : Vector2 = Vector2.ZERO

var mouse_sensitivity : float = 0.01
var pitch_min : float = deg_to_rad(-70)
var pitch_max : float = deg_to_rad(70)
var object_min_distance : float = 1.5
var object_max_distance : float = 8.0
var scroll_speed : float = 0.5
var rotating_object : bool = false
var throw_min_force : float = 20
var throw_max_force : float = 200
var throw_max_charge_time : float = 1.5

var interaction_is_holding := false
var interaction_hold_time := 0.0
var interaction_hold_threshold := 0.3

func _ready():
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_physics_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_process_input(get_multiplayer_authority() == multiplayer.get_unique_id())
	
func _input(event):
	if GameState.menu_visible:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			rotating_object = event.pressed
			
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			object_distance = clamp(object_distance + scroll_speed, object_min_distance, object_max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			object_distance = clamp(object_distance - scroll_speed, object_min_distance, object_max_distance)
		
	if event is InputEventMouseMotion:
		if rotating_object:
			#object_rotation.y = wrapf(object_rotation.y + -event.relative.x * mouse_sensitivity, -PI, PI)
			#object_rotation.x = wrapf(object_rotation.x + -event.relative.y * mouse_sensitivity, -PI, PI)
			object_rotation.y = object_rotation.y + -event.relative.x * mouse_sensitivity
			object_rotation.x = object_rotation.x + -event.relative.y * mouse_sensitivity
		else:
			orientation.y = wrapf(orientation.y + -event.relative.x * mouse_sensitivity, -PI, PI)
			orientation.x = clamp(orientation.x - event.relative.y * mouse_sensitivity, pitch_min, pitch_max)

func _process(delta):
	if GameState.menu_visible:
		interaction_is_holding = false
		return
		
	if interaction_is_holding:
		interaction_hold_time += delta
		
	direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	running = Input.is_action_pressed("move_run")
	crouching = Input.is_action_pressed("move_crouch")
	
	if Input.is_action_just_pressed("move_jump"):
		_handle_jump()
		
	if Input.is_action_just_pressed("interact_secondary"):
		interaction_is_holding = true
		interaction_hold_time = 0.0
	elif Input.is_action_just_released("interact_secondary"):
		interaction_is_holding = false
		_handle_secondary_interaction(interaction_hold_time < interaction_hold_threshold)
		
	if Input.is_action_just_pressed("interact"):
		_handle_primary_interaction()
		
	_handle_interaction_visual_feedback()
	
func _handle_jump():
	jumping = true
	
func _handle_secondary_interaction(short_press : bool):
	if player.held_object:
		if short_press:
			player.held_object.drop.rpc_id(1)
		else:
			var impulse = -player.camera.global_transform.basis.z * lerp(throw_min_force, throw_max_force, clamp(interaction_hold_time / throw_max_charge_time, 0.0, 1.0))
			player.held_object.throw.rpc_id(1, impulse)
	elif short_press:
		var pos = player.camera.global_transform.origin + -player.camera.global_transform.basis.z * 5
		GameState.current_world.spawn_object.rpc_id(1, pos)
	
func _handle_primary_interaction():
	var result = player.ray_cast_interaction.get_collider()
	if result:
		var collider = result
		var collision_point = player.ray_cast_interaction.get_collision_point()
		if collider.is_in_group("interactable"):
			var controller = collider.get_meta("interactable")
			controller.interact.rpc_id(1)
		if collider.is_in_group("driveable"):
			var controller = collider.get_meta("driveable")
			controller.drive.rpc_id(1)
		elif collider.is_in_group("pickable"):
			var controller = collider.get_meta("pickable")
			object_rotation = Vector2.ZERO
			object_distance = clamp(collider.global_position.distance_to(player.global_position), object_min_distance, object_max_distance)
			controller.pickup.rpc_id(1, controller.target.to_local(collision_point))

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
