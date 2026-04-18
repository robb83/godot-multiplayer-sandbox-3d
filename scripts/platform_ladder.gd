@tool
extends Node3D
class_name PlatformLadder

#TODO: Baking/Editor plugin

@export_category("Ladder Settings")
@export var ladder_height: float = 2.0:
	set(value):
		ladder_height = value
		_mark_dirty()

@export var ladder_width: float = 0.5:
	set(value):
		ladder_width = value
		_mark_dirty()

@export var rung_spacing: float = 0.3:
	set(value):
		rung_spacing = value
		_mark_dirty()
		
@export var rail_thickness: float = 0.05:
	set(value):
		rail_thickness = value
		_mark_dirty()
		
@export var material : Material = null:
	set(value):
		material = value
		if mesh_instance_3d:
			mesh_instance_3d.material_override = material

var static_body_3d : StaticBody3D = null
var mesh_instance_3d : MeshInstance3D = null
var collider_shape_3d : CollisionShape3D = null
var dirty : bool = true

func _ready():
	_generate()
	
func _mark_dirty():
	dirty = true
	if is_inside_tree():
		_generate()
		
func _generate():
	if not dirty:
		return
	dirty = false
		
	if collider_shape_3d:
		collider_shape_3d.queue_free()
		
	if mesh_instance_3d:
		mesh_instance_3d.queue_free()
		
	mesh_instance_3d = MeshInstance3D.new()
	mesh_instance_3d.material_override = material
	mesh_instance_3d.mesh = _generate_mesh()
	
	var shape = BoxShape3D.new()
	shape.size = Vector3(ladder_width, ladder_height, rail_thickness)
	
	collider_shape_3d = CollisionShape3D.new()
	collider_shape_3d.shape = shape
	collider_shape_3d.position = Vector3(ladder_width / 2.0, ladder_height / 2, rail_thickness / 2.0)
	
	if not static_body_3d:
		static_body_3d = StaticBody3D.new()
		static_body_3d.add_to_group("ladder")
		add_child(static_body_3d)
	
	static_body_3d.add_child(collider_shape_3d)
	static_body_3d.add_child(mesh_instance_3d)
	
func _generate_mesh():
	if rung_spacing <= 0:
		return
		
	var pole_offset = ladder_width - rail_thickness
	var rung_count = int(ladder_height / (rung_spacing + rail_thickness))
	var offset = ((ladder_height - (rung_count * (rung_spacing + rail_thickness))) / 2.0) + ((rung_spacing + rail_thickness) / 2.0)
	
	var st = SurfaceToolBuilder.new()

	# left pole top
	st.add_vertex(Vector3(0, ladder_height, 0))
	st.add_vertex(Vector3(0, ladder_height, rail_thickness))
	var left_front = st.add_vertex(Vector3(rail_thickness, ladder_height, 0))
	var left_back = st.add_vertex(Vector3(rail_thickness, ladder_height, rail_thickness))
	
	# left pole bottom
	st.add_vertex(Vector3(0, 0, 0))
	st.add_vertex(Vector3(0, 0, rail_thickness))
	var left_bottom_front = st.add_vertex(Vector3(rail_thickness, 0, 0))
	var left_bottom_back = st.add_vertex(Vector3(rail_thickness, 0, rail_thickness))
	
	# right pole top
	var right_front = st.add_vertex(Vector3(pole_offset + 0, ladder_height, 0))
	var right_back = st.add_vertex(Vector3(pole_offset + 0, ladder_height, rail_thickness))
	st.add_vertex(Vector3(pole_offset + rail_thickness, ladder_height, 0))
	st.add_vertex(Vector3(pole_offset + rail_thickness, ladder_height, rail_thickness))
	
	# right pole bottom
	var right_bottom_front = st.add_vertex(Vector3(pole_offset + 0, 0, 0))
	var right_bottom_back = st.add_vertex(Vector3(pole_offset + 0, 0, rail_thickness))
	st.add_vertex(Vector3(pole_offset + rail_thickness, 0, 0))
	st.add_vertex(Vector3(pole_offset + rail_thickness, 0, rail_thickness))
	
	# left pole faces
	st.add_face([2,3,1,2,1,0]) # top cap
	st.add_face([4,5,6,5,7,6]) # bottom cap
	st.add_face([0,1,4,1,5,4]) # outer side
	st.add_face([4,6,2,4,2,0]) # front side
	st.add_face([1,3,5,3,7,5]) # back side
	#st.add_face([6,7,3,6,3,2]) # inner side
	
	# right pole faces
	st.add_face([10,11,9,10,9,8]) # top cap
	st.add_face([12,13,14,13,15,14]) # bottom cap
	#st.add_face([8,9,12,9,13,12]) # inner side
	st.add_face([12,14,10,12,10,8]) # front side
	st.add_face([9,11,13,11,15,13]) # back side
	st.add_face([14,15,11,14,11,10]) # outer side
	
	for i in range(rung_count):		
		# left - rung top (1,2)
		var left_rung_top_front = st.add_vertex(Vector3(rail_thickness, ladder_height - offset, 0))
		var left_rung_top_back = st.add_vertex(Vector3(rail_thickness, ladder_height - offset, rail_thickness))
		
		# right - rung top (3,4)
		var right_rung_top_front = st.add_vertex(Vector3(pole_offset + 0, ladder_height - offset, 0))
		var right_rung_top_back = st.add_vertex(Vector3(pole_offset + 0, ladder_height - offset, rail_thickness))
		
		offset += rail_thickness
		
		# left - rung bottom (5,6)
		var left_rung_bottom_front = st.add_vertex(Vector3(rail_thickness, ladder_height - offset, 0))
		var left_rung_bottom_back = st.add_vertex(Vector3(rail_thickness, ladder_height - offset, rail_thickness))
		
		# right - rung bottom (7,8)
		var right_rung_bottom_front = st.add_vertex(Vector3(pole_offset + 0, ladder_height - offset, 0))
		var right_rung_bottom_back = st.add_vertex(Vector3(pole_offset + 0, ladder_height - offset, rail_thickness))

		st.add_face([left_rung_top_front, left_rung_top_back, left_back, left_rung_top_front, left_back, left_front])
		st.add_face([right_front, right_back, right_rung_top_front, right_back, right_rung_top_back, right_rung_top_front])
		st.add_face([right_rung_top_front, right_rung_top_back, left_rung_top_back, right_rung_top_front, left_rung_top_back, left_rung_top_front])
		st.add_face([left_rung_bottom_front, left_rung_bottom_back, right_rung_bottom_front, left_rung_bottom_back, right_rung_bottom_back, right_rung_bottom_front])
		st.add_face([left_rung_bottom_front, right_rung_bottom_front, right_rung_top_front, left_rung_bottom_front, right_rung_top_front, left_rung_top_front])
		st.add_face([left_rung_top_back, right_rung_top_back, left_rung_bottom_back, right_rung_top_back, right_rung_bottom_back, left_rung_bottom_back])
		
		offset += rung_spacing
		left_front = left_rung_bottom_front
		left_back = left_rung_bottom_back
		right_front = right_rung_bottom_front
		right_back = right_rung_bottom_back
		
	st.add_face([left_bottom_front, left_bottom_back, left_back, left_bottom_front, left_back, left_front])
	st.add_face([right_front,right_back,right_bottom_front,right_back,right_bottom_back,right_bottom_front])
	
	st.generate_normals()
	return st.commit()
	
