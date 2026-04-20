extends Node3D
class_name EndlessChunkInstance

var players = {}
var index : int = -1
var version : int = 1
var generated : bool = false
var manager : EndlessChunkManager = null

func _enter_tree() -> void:
	set_synchronizers_public_visibility(false)
	set_synchronizers_visibility_for(get_multiplayer_authority(), true)

func _ready():
	pass
	
func get_chunk_state() -> Dictionary:
	return { "version": version, "generated": generated }

func set_chunk_state(state : Dictionary):
	if state:
		generated = state.generated
		
func generate():
	generated = true
		
func set_synchronizers_visibility_for(peer_id : int, value: bool) -> void:
	if is_multiplayer_authority() and peer_id != get_multiplayer_authority():
		if not value:
			if players.has(peer_id):
				players.erase(peer_id)
		elif value:
			players[peer_id] = true
		
	GameState.set_synchronizers_visibility_for(self, peer_id, value)
	
func set_synchronizers_public_visibility(value: bool) -> void:
	GameState.set_synchronizers_public_visibility(self, value)
