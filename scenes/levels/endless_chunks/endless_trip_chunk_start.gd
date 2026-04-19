extends EndlessChunkInstance

@onready var garage: Node3D = $StaticObjects/Garage
@onready var vehicle_spawn: Node3D = $DynamicObjects/VehicleSpawn

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
	generated = true
	manager.spawn_dynamics_object("res://objects/vehicle_car.tscn", vehicle_spawn.global_position)
