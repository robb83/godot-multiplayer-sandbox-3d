extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animatable_body_3d: AnimatableBody3D = $AnimatableBody3D
@onready var csg_combiner_3d: CSGCombiner3D = $CSGCombiner3D

var state_open : bool = false

func _ready():
	animatable_body_3d.set_meta('interactable', self)

func set_state(open : bool):
	state_open = open
	if state_open:
		animation_player.current_animation = "door_open"
	else:
		animation_player.current_animation = "door_close"
		
func _update_state():
	if animation_player.is_playing():
		return
	set_state(not state_open)

@rpc("any_peer", "call_local")
func interact():
	if multiplayer.is_server():
		_update_state()
