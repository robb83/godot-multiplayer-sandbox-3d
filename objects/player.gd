extends CharacterBody3D
class_name Player

@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer1
@onready var mouse_state_indicator: MouseStateIndicator = $MouseStateIndicator
@onready var player_input: PlayerInput = $PlayerInput
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var ray_cast_down: RayCast3D = $RayCastDown
@onready var ray_cast_forward: RayCast3D = $CameraPivot/Camera3D/RayCastForward
@onready var ray_cast_interaction: RayCast3D = $CameraPivot/Camera3D/RayCastInteraction
@onready var ray_cast_up: RayCast3D = $RayCastUp
@onready var visuals: Node3D = $Visuals
@onready var visual_eye_right: MeshInstance3D = $Visuals/VisualFace/VisualEyeRight
@onready var visual_eye_left: MeshInstance3D = $Visuals/VisualFace/VisualEyeLeft
@onready var visual_face: Node3D = $Visuals/VisualFace
@onready var visual_body_crouch: MeshInstance3D = $Visuals/VisualBodyCrouch
@onready var visual_body_stand: MeshInstance3D = $Visuals/VisualBodyStand
@onready var collision_crouch: CollisionShape3D = $CollisionCrouch
@onready var collision_stand: CollisionShape3D = $CollisionStand

@export var held_object_position : Vector3 = Vector3.ZERO
@export var held_object_rotation : Vector2 = Vector2.ZERO
@export var crouching : bool = false
@export var player_peer_id := 1:
	set(peer_id):
		player_peer_id = peer_id
		$PlayerInput.set_multiplayer_authority(peer_id)

var current_map = null
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed = 0.0
var acceleration = 2.0
var walk_speed = 6.0
var run_speed = 10.0
var crouch_speed = 3.0
var jump_force = 4.0
var max_velocity : float = 20.0
var strength : float = 100
var held_object = null

func set_held_object(object):
	held_object = object

func _ready():
	if player_peer_id == multiplayer.get_unique_id():
		visuals.visible = false
		camera_pivot.visible = true
		camera.current = true
		mouse_state_indicator.visible = true
		ray_cast_down.visible = true
		ray_cast_down.enabled = true
		ray_cast_up.visible = true
		ray_cast_up.enabled = true
		ray_cast_interaction.visible = true
		ray_cast_interaction.enabled = true
		ray_cast_interaction.add_exception(self)
		ray_cast_forward.visible = true
		ray_cast_forward.enabled = true
	
	# needed for server to check space above head
	if is_multiplayer_authority():
		ray_cast_up.visible = true
		ray_cast_up.enabled = true
	
func _physics_process(delta):
	var owners = player_peer_id == multiplayer.get_unique_id() or is_multiplayer_authority()
	if owners:
		_process_authority(delta)
	else:
		_process_clients(delta)

func _process_clients(_delta):
	_change_collision()
	
func _process_authority(delta):
	if crouching and not player_input.crouching:
		crouching = ray_cast_up.get_collider() != null
	else:
		crouching = player_input.crouching
	
	_change_collision()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	var cam_transform = camera.global_transform
	held_object_position = cam_transform.origin + -cam_transform.basis.z * player_input.hold_distance
	held_object_rotation = player_input.object_rotation
		
	camera.rotation.x = player_input.orientation.x
	self.rotation.y = player_input.orientation.y
	
	visual_eye_left.rotation.x = player_input.orientation.x
	visual_eye_right.rotation.x = player_input.orientation.x

	if player_input.jumping and is_on_floor():
		velocity.y = jump_force
		player_input.jumping = false

	var target_speed = run_speed if player_input.running else walk_speed
	if crouching:
		target_speed = crouch_speed
		
	current_speed = lerp(current_speed, target_speed, acceleration * delta)
	
	var direction = (transform.basis * Vector3(player_input.direction.x, 0, player_input.direction.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)

	#NOTE: first try to reduce big push from rigidbodies
	if velocity.length() > max_velocity:
		velocity = velocity.normalized() * max_velocity
	
	move_and_slide()

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
