extends Node3D
class_name EndlessChunkInstance

var index : int = -1
var version : int = 1
var generated : bool = false
var manager : EndlessChunkManager = null

func _enter_tree() -> void:
	GameState.set_synchronizers_public_visibility(self, false)
	GameState.set_synchronizers_visibility_for(self, get_multiplayer_authority(), true)

func _ready():
	pass
	
func get_chunk_state() -> Dictionary:
	return { "version": version, "generated": generated }

func set_chunk_state(state : Dictionary):
	if state:
		generated = state.generated
		
func generate():
	generated = true
