extends Node3D
class_name EndlessChunkInstance

var players = {}

func _ready():
	set_synchronizers_visibility_safe(false)
	if not is_multiplayer_authority():
		set_synchronizers_visibility_for(1, true)

func set_synchronizers_visibility_for(peer_id : int, value: bool) -> void:
	if not visible and players.has(peer_id):
		players.erase(peer_id)
	elif visible:
		players[peer_id] = true
		
	_set_synchronizers_visibility_for(self, peer_id, value)
	
func _set_synchronizers_visibility_for(root: Node, peer_id : int, value: bool) -> void:
	if !is_instance_valid(root):
		return
	
	if root is MultiplayerSynchronizer:
		root.set_visibility_for(peer_id, value)
		
	for child in root.get_children():
		_set_synchronizers_visibility_for(child, peer_id, value)

func set_synchronizers_visibility_safe(value: bool) -> void:
	_set_synchronizers_visibility_safe(self, value)
	
func _set_synchronizers_visibility_safe(root: Node, value: bool) -> void:
	if !is_instance_valid(root):
		return
	
	if root is MultiplayerSynchronizer:
		root.public_visibility = false
		
	for child in root.get_children():
		_set_synchronizers_visibility_safe(child, value)
