extends Node
class_name Pickable

const max_distance : float = 12
const angular_force : float = 15.0
const too_weak : float = 6.0 #TODO:

@export var target : Node3D = null
var target_has_callback : bool = false
var player : Player = null
var grab_point : Vector3 = Vector3.ZERO
var rotation_progress : Vector2 = Vector2.ZERO

func _ready():
	if target:
		target.add_to_group("pickable", true)
		target.set_meta("pickable", self)
		target_has_callback = target.has_method("can_pickup")
	else:
		printerr("[Pickable] target is null")
	
func _physics_process(_delta: float) -> void:
	_held_object_check()
	_held_object_move()

func _held_object_check():
	if player and (multiplayer.is_server() or player.player_peer_id == multiplayer.get_unique_id()):
		if not is_instance_valid(player):
			drop.rpc_id(G.SERVER_PEER_ID)
			return
		
		if player.global_position.distance_to(target.global_position) >= max_distance:
			drop.rpc_id(G.SERVER_PEER_ID)
			return
			
		var current_pos = target.to_global(grab_point)
		var linear_movement = player.held_object_position - current_pos
		if linear_movement.length() > too_weak:
			drop.rpc_id(G.SERVER_PEER_ID)
			return
			
func _held_object_move():
	if player and is_instance_valid(player):
		#var current_pos = global_transform.origin
		var current_pos = target.to_global(grab_point)
		var linear_movement = player.held_object_position - current_pos
		
		if linear_movement.length() > too_weak:
			return
		
		# linear movement
		target.linear_velocity = (linear_movement * player.strength) / target.mass
		
		# angular movement or rotation
		var diff = player.held_object_rotation - rotation_progress
		rotation_progress = player.held_object_rotation
		#held_object.rotate(camera.global_transform.basis.x, -wrapf(diff.x, -PI, PI))
		#held_object.rotate(camera.global_transform.basis.y, -wrapf(diff.y, -PI, PI))
		var target_angular_velocity = Vector3(-diff.x, -diff.y, 0.0) * angular_force
		var delta_av = target_angular_velocity - target.angular_velocity
		var torque = delta_av * player.strength
		target.apply_torque(torque)
	
@rpc("any_peer", "call_local")
func pickup(gp : Vector3):
	if multiplayer.is_server():
		if player:
			return
		if not target_has_callback or (target_has_callback and target.can_pickup()):
			var peer_id = multiplayer.get_remote_sender_id()
			var p = GameState.current_world.get_player_by_peer(peer_id)
			if p and is_instance_valid(p) and p.held_object == null:
				if gp and gp.length() < max_distance and p.global_position.distance_to(target.global_position) < max_distance:
					set_player.rpc(peer_id, gp)

@rpc("any_peer", "call_local")
func drop():
	if multiplayer.is_server():
		var peer_id = multiplayer.get_remote_sender_id()
		if player and peer_id == player.player_peer_id:
			set_player.rpc(-1, Vector3.ZERO)

@rpc("any_peer", "call_local")
func throw(impulse):
	if multiplayer.is_server():
		var peer_id = multiplayer.get_remote_sender_id()
		if player and peer_id == player.player_peer_id:
			set_player.rpc(-1, Vector3.ZERO)
			target.apply_impulse(impulse)
		
@rpc("authority", "call_local")
func set_player(peer_id : int, gp : Vector3):
	if player:
		target.remove_collision_exception_with(player)
		player.set_held_object(null)
		
	rotation_progress = Vector2.ZERO
	grab_point = gp
	player = GameState.current_world.get_player_by_peer(peer_id)
	
	if player and is_instance_valid(player):
		target.add_collision_exception_with(player)
		player.set_held_object(self)
