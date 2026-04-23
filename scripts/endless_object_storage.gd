extends RefCounted
class_name EndlessObjectStorage

var chunk_length := 50.0
var chunks: Dictionary = {}
var object_to_chunk: Dictionary = {}

func _init(length : float = 50.0):
	chunk_length = length

func _create_object(id: int, scene: String, pos: Vector3, rot: Vector3) -> Dictionary:
	return { "id": id, "scene": scene, "pos": pos, "rot": rot }

func get_chunk_index(z_pos: float) -> int:
	return int(floor(z_pos / chunk_length))
	
func update_object(id: int, scene: String, pos: Vector3, rot: Vector3):
	var current_chunk = get_chunk_index(pos.z)
	if current_chunk < 0: current_chunk = 0

	if object_to_chunk.has(id):
		var previous_chunk = object_to_chunk[id]

		if previous_chunk != current_chunk:
			object_to_chunk[id] = current_chunk
			chunks[previous_chunk].erase(id)
	else:
		object_to_chunk[id] = current_chunk
	
	if not chunks.has(current_chunk):
		chunks[current_chunk] = {}
			
	chunks[current_chunk][id] = _create_object(id, scene, pos, rot)

func get_objects(z_pos: float, radius: float) -> Array:
	var center = get_chunk_index(z_pos)
	var r = int(ceil(radius / chunk_length))
	var result: Array = []
	
	for i in range(center - r, center + r + 1):
		if chunks.has(i):
			result.append_array(chunks[i].values())

	return result
