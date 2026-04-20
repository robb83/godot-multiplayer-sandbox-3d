extends EndlessChunkInstance

@onready var label_3d: Label3D = $StaticObjects/StaticBody3D2/Label3D
@onready var garage: Node3D = $StaticObjects/Garage
@onready var vehicle_spawn: Node3D = $DynamicObjects/VehicleSpawn

func _ready():
	super._ready()
	label_3d.text = "%s / %s" % [index, label_3d.global_position.z]
	
func get_chunk_state() -> Dictionary:
	var open = garage.state_open
	var state = super.get_chunk_state()
	state["garage"] = open
	return state

func set_chunk_state(state : Dictionary):
	super.set_chunk_state(state)
	if state and state.has("garage"):
		garage.set_state(state["garage"])
	
func generate():
	super.generate()
	manager.spawn_dynamic_object("res://objects/vehicle_car.tscn", vehicle_spawn.global_position, Vector3.ZERO)
