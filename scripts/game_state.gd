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
