extends Node

@export var menu_visible : bool = false
@export var current_world = null
@export var selected_world = null

func get_worlds() -> Array:
	var result = []
	var resources = ResourceLoader.list_directory("res://scenes/levels")
	for r in resources:
		if r.ends_with(".tscn"):
			result.append({ "name": r.get_basename(), "path": "res://scenes/levels/" + r })
	return result

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
