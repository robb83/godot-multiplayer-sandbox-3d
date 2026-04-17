extends Node
class_name PlayerVehicleInput

@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

@export var player : Player = null
@export var input_throttle : float = 0.0
@export var input_brake : float = 0.0
@export var input_steering : float = 0.0
@export var input_horn : bool = false

func _ready():
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_physics_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_process_input(get_multiplayer_authority() == multiplayer.get_unique_id())
	multiplayer_synchronizer.add_visibility_filter(func (id): return player.vehicle_driver )
	
func _physics_process(delta: float):
	_read_input()
	
func _read_input():
	if not is_multiplayer_authority():
		return
		
	if not player.vehicle_object:
		return
		
	if not player.vehicle_driver:
		return
		
	input_throttle = clamp(Input.get_action_strength("vehicle_throttle"), 0.0, 1.0)
	input_brake = clamp(Input.get_action_strength("vehicle_brake"), 0.0, 1.0)
	input_steering = clamp(Input.get_action_strength("vehicle_steer_left") - Input.get_action_strength("vehicle_steer_right"), -1.0, 1.0)
	input_horn = Input.is_action_pressed("vehicle_horn")
	
	var vehicle = player.vehicle_object

	if Input.is_action_just_pressed("vehicle_gear_up"):
		vehicle.shift_up.rpc_id(1)
	if Input.is_action_just_pressed("vehicle_gear_down"):
		vehicle.shift_down.rpc_id(1)
	if Input.is_action_just_pressed("vehicle_handbrake"):
		vehicle.toggle_handbrake.rpc_id(1)
	if Input.is_action_just_pressed("vehicle_indicator_left"):
		vehicle.toggle_indicator_left.rpc_id(1)
	if Input.is_action_just_pressed("vehicle_indicator_right"):
		vehicle.toggle_indicator_right.rpc_id(1)
	if Input.is_action_just_pressed("vehicle_hazard"):
		vehicle.toggle_indicator_hazard.rpc_id(1)
	if Input.is_action_just_pressed("vehicle_lights"):
		vehicle.toggle_lights.rpc_id(1)
	if Input.is_action_just_pressed("vehicle_highbeam"):
		vehicle.toggle_highbeam.rpc_id(1)
