extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if is_multiplayer_authority():
		animation_player.current_animation = "platform_rotate"
