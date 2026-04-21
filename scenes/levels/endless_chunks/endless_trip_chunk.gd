extends EndlessChunkInstance

@onready var label_3d: Label3D = $StaticObjects/StaticBody3D2/Label3D

func _ready():
	super._ready()
	label_3d.text = "%s / %s" % [index, label_3d.global_position.z]
	
func generate():
	super.generate()
	
	for y in range(2):
		for x in range(2):
			for z in range(2):
				manager.spawn_dynamic_object("res://objects/pickable_03.tscn", Vector3(global_position.x + x, global_position.y + 0.6 + y, global_position.z + z) , Vector3.ZERO)
