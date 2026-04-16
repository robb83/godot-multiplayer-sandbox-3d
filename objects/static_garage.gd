extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animatable_body_3d: AnimatableBody3D = $AnimatableBody3D
@onready var csg_combiner_3d: CSGCombiner3D = $CSGCombiner3D

var state_open : bool = false

func _ready():
	animatable_body_3d.set_meta('object', self)
	
func _update_state():
	if animation_player.is_playing():
		return
	state_open = not state_open
	if state_open:
		animation_player.current_animation = "door_open"
	else:
		animation_player.current_animation = "door_close"

@rpc("any_peer", "call_local")
func interact():
	if multiplayer.is_server():
		_update_state()
