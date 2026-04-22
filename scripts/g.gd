extends Node

const SERVER_PEER_ID : int = 1

func set_synchronizers_visibility_for(root: Node, peer_id : int, value: bool) -> void:
	if !is_instance_valid(root):
		return

	if root is MultiplayerSynchronizer:
		root.set_visibility_for(peer_id, value)
		
	for child in root.get_children():
		set_synchronizers_visibility_for(child, peer_id, value)

func set_synchronizers_public_visibility(root: Node, value: bool) -> void:
	if !is_instance_valid(root):
		return
	
	if root is MultiplayerSynchronizer:
		root.public_visibility = value
		
	for child in root.get_children():
		set_synchronizers_public_visibility(child, value)
		
func set_synchronizers_add_visibility_filter(root: Node, filter: Callable) -> void:
	if !is_instance_valid(root):
		return
	
	if root is MultiplayerSynchronizer:
		root.add_visibility_filter(filter)
		
	for child in root.get_children():
		set_synchronizers_add_visibility_filter(child, filter)
		
func set_synchronizers_remove_visibility_filter(root: Node, filter: Callable) -> void:
	if !is_instance_valid(root):
		return
	
	if root is MultiplayerSynchronizer:
		root.remove_visibility_filter(filter)
		
	for child in root.get_children():
		set_synchronizers_remove_visibility_filter(child, filter)
