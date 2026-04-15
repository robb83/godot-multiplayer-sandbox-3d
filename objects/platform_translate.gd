extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animatable_body_3d: AnimatableBody3D = $AnimatableBody3D

func _ready():
	if is_multiplayer_authority():
		animation_player.current_animation = "platform_moving"
