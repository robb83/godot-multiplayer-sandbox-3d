extends RefCounted
class_name SurfaceToolBuilder

var surface_tool : SurfaceTool = null
var vertext_index : int = -1

func _init() -> void:
	surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
func last_vertex_index():
	return vertext_index
	
func add_face(indecies : Array):
	for i in indecies:
		surface_tool.add_index(i)
		
func add_vertex(vertex:Vector3) -> int:
	vertext_index += 1
	surface_tool.add_vertex(vertex)
	return vertext_index
	
func generate_normals():
	surface_tool.generate_normals()
	
func commit():
	return surface_tool.commit()
