extends CharacterBody3D
class_name Player

@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var mouse_state_indicator: MouseStateIndicator = $MouseStateIndicator
@onready var player_input: PlayerInputMovement = $PlayerInputMovement
@onready var player_input_vehicle: PlayerInputVehicle = $PlayerVehicleInput
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var ray_cast_down: RayCast3D = $RayCastDown
@onready var ray_cast_forward: RayCast3D = $CameraPivot/Camera3D/RayCastForward
@onready var ray_cast_interaction: RayCast3D = $CameraPivot/Camera3D/RayCastInteraction
@onready var visuals: Node3D = $Visuals
@onready var visual_eye_right: MeshInstance3D = $Visuals/VisualFace/VisualEyeRight
@onready var visual_eye_left: MeshInstance3D = $Visuals/VisualFace/VisualEyeLeft
@onready var visual_face: Node3D = $Visuals/VisualFace
@onready var visual_body_crouch: MeshInstance3D = $Visuals/VisualBodyCrouch
@onready var visual_body_stand: MeshInstance3D = $Visuals/VisualBodyStand
@onready var collision_crouch: CollisionShape3D = $CollisionCrouch
@onready var collision_stand: CollisionShape3D = $CollisionStand
@onready var shape_cast_stand: ShapeCast3D = $ShapeCastStand
@onready var ray_cast_obstacle_detection: RayCast3D = $CameraPivot/Camera3D/RayCastObstacleDetection
@onready var ray_cast_3d_landing_point: RayCast3D = $RayCast3DLandingPoint
@onready var shape_cast_head: ShapeCast3D = $Visuals/VisualFace/ShapeCastHead

@export var held_object_position : Vector3 = Vector3.ZERO
@export var held_object_rotation : Vector2 = Vector2.ZERO
@export var crouching : bool = false
@export var player_peer_id := 1

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var acceleration : float = 2.0
var walk_speed : float = 6.0
var run_speed : float = 10.0
var crouch_speed : float = 3.0
var jump_force : float = 4.0
var max_velocity : float = 20.0
var strength : float = 100
var held_object = null
var vehicle_object = null
var vehicle_seat_transform = null
var vehicle_driver = false
var jumping : bool = false
var running : bool = false
var direction : Vector2 = Vector2.ZERO
var is_on_ladder : bool = false
var ladder_speed : float = 1.0

func set_held_object(object):
	held_object = object

func set_vehicle(vehicle, seat_transform : Transform3D, can_drive : bool):
	vehicle_object = vehicle
	vehicle_seat_transform = seat_transform
	vehicle_driver = can_drive
	if is_multiplayer_authority():
		if seat_transform:
			player_input.orientation.y = seat_transform.basis.get_euler().y
	
func _enter_tree() -> void:
	set_multiplayer_authority(player_peer_id)
	
func _ready():
	
	if is_multiplayer_authority():
		visuals.visible = false
		camera_pivot.visible = true
		camera.current = true
		mouse_state_indicator.visible = true
		ray_cast_down.visible = true
		ray_cast_down.enabled = true
		ray_cast_interaction.visible = true
		ray_cast_interaction.enabled = true
		ray_cast_interaction.add_exception(self)
		ray_cast_forward.visible = true
		ray_cast_forward.enabled = true
		ray_cast_obstacle_detection.visible = true
		ray_cast_obstacle_detection.enabled = true
		ray_cast_3d_landing_point.visible = true
		ray_cast_3d_landing_point.enabled = true
		shape_cast_stand.visible = true
		shape_cast_head.add_exception(self)
		shape_cast_head.visible = true
		shape_cast_head.enabled = true

func _process(_delta):
	if is_multiplayer_authority():
		if crouching and not player_input.crouching:
			crouching = shape_cast_stand.is_colliding()
		else:
			crouching = player_input.crouching
		shape_cast_stand.enabled = crouching
		
		direction = player_input.direction
		running = player_input.running
		jumping = jumping or player_input.jumping
		player_input.jumping = false
		
		camera.rotation.x = player_input.orientation.x
		rotation.y = player_input.orientation.y
	
		visual_eye_left.rotation.x = player_input.orientation.x
		visual_eye_right.rotation.x = player_input.orientation.x
	
		var cam_transform = camera.global_transform
		held_object_position = cam_transform.origin + -cam_transform.basis.z * player_input.object_distance
		held_object_rotation = player_input.object_rotation
	
		if vehicle_object:
			crouching = true
			var target_position = vehicle_object.to_global(vehicle_seat_transform.origin)
			position = target_position
			rotation.y = player_input.orientation.y + vehicle_object.rotation.y
	else:
		if vehicle_object:
			crouching = true
			var target_position = vehicle_object.to_global(vehicle_seat_transform.origin)
			position = target_position
			#TODO: need to rotate relative to vehicle?
			
func _physics_process(delta):
	
	_change_collision()

	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if vehicle_object:
		return
		
	if is_multiplayer_authority():
		if is_on_ladder:
			_handle_ladder(delta)
			return
			
		if jumping:
			if ray_cast_obstacle_detection.is_colliding():
				var collider = ray_cast_3d_landing_point.get_collider()
				if collider and not shape_cast_head.is_colliding():
					jumping = false
					var collider_point = ray_cast_3d_landing_point.get_collision_point()
					global_position = collider_point + Vector3(0, 1.1, 0)
				
			if jumping and is_on_floor():
				velocity.y = jump_force
		jumping = false

		var movement_speed = crouch_speed if crouching else (run_speed if running else walk_speed)
		var movement_direction = (transform.basis * Vector3(direction.x, 0, direction.y)).normalized()
		
		if movement_direction:
			velocity.x = movement_direction.x * movement_speed
			velocity.z = movement_direction.z * movement_speed
		else:
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0, movement_speed)
				velocity.z = move_toward(velocity.z, 0, movement_speed)

		#NOTE: first try to reduce big push from rigidbodies
		if velocity.length() > max_velocity:
			velocity = velocity.normalized() * max_velocity
		
		move_and_slide()
		
		_ladder_check()

func _handle_ladder(delta):
	if is_on_floor() and direction.y > 0:
		is_on_ladder = false
		return
		
	velocity = Vector3(direction.x * ladder_speed * 0.5, -direction.y * ladder_speed, 0.0)
	
	if jumping:
		is_on_ladder = false
		velocity.y = jump_force
		move_and_slide()
		return
	jumping = false
	
	move_and_slide()
	
	is_on_ladder = _ladder_touching()

func _ladder_touching():
	var collider = ray_cast_forward.get_collider()
	return collider and collider.is_in_group("ladder")
	
func _ladder_check():
	var collider = ray_cast_forward.get_collider()
	if collider and collider.is_in_group("ladder") and direction.y < 0:
		var forward = -camera.global_transform.basis.z
		var ladder_forward = -collider.global_transform.basis.z
		if forward.dot(ladder_forward) > 0.7:
			is_on_ladder = true
		
func _change_collision():
	if crouching:
		collision_stand.disabled = true
		collision_crouch.disabled = false
		visual_body_stand.visible = false
		visual_body_crouch.visible = true
		visual_face.position = Vector3(0, -0.5, 0)
		camera_pivot.position = Vector3(0, 0.9, 0)
	else:
		collision_stand.disabled = false
		collision_crouch.disabled = true
		visual_body_stand.visible = true
		visual_body_crouch.visible = false
		visual_face.position = Vector3.ZERO
		camera_pivot.position = Vector3(0, 1.6, 0)
