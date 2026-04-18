extends VehicleBody3D


# Engine sound by Dmitry_mansurev64 (Freesound)
# Licensed under CC BY 0.0
# https://freesound.org/people/Dmitry_mansurev64/sounds/748027/

# Blinker sound by dersuperanton (Freesound)
# Licensed under CC BY 4.0
# https://freesound.org/people/dersuperanton/sounds/434819/

@onready var driver_seat_1: Node3D = $Seats/DriverSeat1
@onready var passanger_seat_1: Node3D = $Seats/PassangerSeat1
@onready var engine_sound: AudioStreamPlayer3D = $EngineSound
@onready var blinker_sound: AudioStreamPlayer3D = $BlinkerSound
@onready var horn_sound: AudioStreamPlayer3D = $HornSound

@onready var wheel_fr: VehicleWheel3D = $Wheel_FR
@onready var wheel_rl: VehicleWheel3D = $Wheel_RL
@onready var wheel_rr: VehicleWheel3D = $Wheel_RR
@onready var wheel_fl: VehicleWheel3D = $Wheel_FL

@onready var light_front_right: SpotLight3D = $LightFrontRight
@onready var light_front_left: SpotLight3D = $LightFrontLeft
@onready var light_rear_right: SpotLight3D = $LightRearRight
@onready var light_rear_left: SpotLight3D = $LightRearLeft
@onready var light_rear_right_indicator: SpotLight3D = $LightRearRightIndicator
@onready var light_rear_left_indicator: SpotLight3D = $LightRearLeftIndicator
@onready var light_front_right_indicator: SpotLight3D = $LightFrontRightIndicator
@onready var light_front_left_indicator: SpotLight3D = $LightFrontLeftIndicator
@onready var light_rear_reverse_left: SpotLight3D = $LightRearReverseLeft
@onready var light_rear_reverse_right: SpotLight3D = $LightRearReverseRight

const min_volume_db := -20
const max_volume_db := 0
const min_pitch := 0.8
const max_pitch := 2.2

@export_category("Engine, Break, Steering")
@export var steering_scale = 0.5
@export var gear_ratios := [-1.5, 0, 1.5, 1.75, 2.3, 2.7, 3.1]
@export var shift_time := 0.2
@export var engine_torque := 2000.0
@export var handbrake_force := 75.0
@export var brake_force := 50.0
@export var engine_max_rpm := 7000.0
@export var engine_idle_rpm := 900.0

@export_category("Simulation")
@export var engine_rpm := 0.0
@export var current_gear = 1
@export var handbrake := false
@export var clutch := 1.0
@export var horn := false
@export var lights := false
@export var highbeam := false
@export var indicator_left := false
@export var indicator_right := false
@export var indicator_hazard := false

var player_driver = null
var player_passanger = null

var wheel_radius = 0.4
var shift_timer := 0.0
var shifting := false
var input_throttle : float = 0.0
var input_brake : float = 0.0
var input_steering : float = 0.0

var blink_interval := 0.4
var blink_timer := 0.0
var blinker_value := false
var blinker_enabled := false

func can_pickup():
	return player_driver == null and player_passanger == null
	
func _ready():
	driver_seat_1.set_meta('driveable', self)
	passanger_seat_1.set_meta('interactable', self)
	engine_sound.play()
	wheel_radius = wheel_fr.wheel_radius
	
func _process(_delta: float):
	_handle_horn_sound()
	_handle_lights(_delta)
	_update_engine_sound(engine_rpm, engine_max_rpm)
	
func _physics_process(delta):
	_read_input()
	_update_transmission(delta)
	_apply_input(delta)
	
func _read_input():
	if player_driver and is_instance_valid(player_driver):
		var input = player_driver.player_input_vehicle
		
		input_throttle = input.input_throttle
		input_brake = input.input_brake
		input_steering = input.input_steering
		horn = input.input_horn
	else:
		input_throttle = 0.0
		input_brake = 0.0
		input_steering = 0.0
		horn = 0.0
	
func _handle_horn_sound():
	#TODO: proper horn sound and logic
	if horn:
		if not horn_sound.playing:
			horn_sound.play()
		var pos = horn_sound.get_playback_position()
		if pos >= 0.55:
			horn_sound.seek(0.18)
			
func _update_engine_sound(rpm: float, max_rpm: float):
	var rpm_ratio = rpm / max_rpm
	var pitch = lerp(min_pitch, max_pitch, pow(rpm_ratio, 1.5))
	var volume = lerp(min_volume_db, max_volume_db, rpm_ratio)
	
	engine_sound.pitch_scale = pitch
	engine_sound.volume_db = volume
	
func _apply_input(delta):
	##TODO: need some research; idk what im doing...
	var engine_target_rpm := engine_idle_rpm + input_throttle * (engine_max_rpm - engine_idle_rpm)
	var engine_rec_up_speed_free = 3000 * (1 - clutch)
	var engine_rec_up_speed_fall_engaed = 1000 * (1 - input_throttle)
	var engine_rev_up_speed = 2000 + engine_rec_up_speed_free + engine_rec_up_speed_fall_engaed
	engine_rpm = move_toward(engine_rpm, engine_target_rpm, engine_rev_up_speed * delta)
	
	var gear_ratio = gear_ratios[current_gear]
	var rpm_ratio = engine_rpm / engine_max_rpm
	var target_force = engine_torque * gear_ratio * rpm_ratio * clutch
	
	# acceleration panelty
	
	engine_force = target_force
	brake = input_brake * brake_force + (handbrake_force if handbrake else 0.0)
	steering = input_steering * steering_scale
		

func _handle_lights(_delta):
	var indicator_required = (indicator_left or indicator_right or indicator_hazard)
	
	if indicator_required and not blinker_enabled:
		blinker_enabled = true
		blinker_value = true
		blink_timer = 0.0
		blinker_sound.play()
	elif not indicator_required:
		blinker_enabled = false
		blinker_value = false
		blink_timer = 0.0
		blinker_sound.stop()
		
	if blinker_enabled:
		blink_timer = blink_timer + _delta
		if blink_timer >= blink_interval:
			blink_timer -= blink_interval
			blinker_value = not blinker_value
		
	light_rear_reverse_left.visible = current_gear == 0
	light_rear_reverse_right.visible = current_gear == 0
		
	if input_brake > 0.0:
		light_rear_left.visible = true
		light_rear_left.light_energy = 20
		light_rear_right.visible = true
		light_rear_right.light_energy = 20
	else:
		light_rear_left.light_energy = 7
		light_rear_left.visible = lights
		light_rear_right.light_energy = 7
		light_rear_right.visible = lights
	
	light_front_left.visible = lights
	light_front_right.visible = lights
	if highbeam:
		light_front_left.light_energy = 20
		light_front_right.light_energy = 20
	else:
		light_front_left.light_energy = 10
		light_front_right.light_energy = 10
		
	var li = (indicator_left or indicator_hazard) and blinker_value
	var ri = (indicator_right or indicator_hazard) and blinker_value
	
	light_front_left_indicator.visible = li
	light_rear_left_indicator.visible = li
	light_front_right_indicator.visible = ri
	light_rear_right_indicator.visible = ri

func _update_transmission(delta):
	if shifting:
		shift_timer -= delta
		clutch = 0.0
		if shift_timer <= 0:
			engine_rpm = clamp(engine_rpm - 1500, engine_idle_rpm, engine_max_rpm)
			shifting = false
			clutch = 1.0
		
func _shift_gear(new_gear):
	new_gear = clamp(new_gear, 0, gear_ratios.size() - 1)
	if new_gear == current_gear:
		return
	current_gear = new_gear
	shifting = true
	shift_timer = shift_time

@rpc("any_peer", "call_local")
func interact():
	if multiplayer.is_server():
		var peer_id = multiplayer.get_remote_sender_id()
		var p = GameState.current_world.get_player_by_peer(peer_id)
		
		if player_passanger:
			if player_passanger == p:
				set_passanger.rpc(-1)
			return
			
		if p.vehicle_object:
			if p.vehicle_object == self and player_driver == p:
				set_driver.rpc(-1)
				set_passanger.rpc(peer_id)
		else:
			set_passanger.rpc(peer_id)

@rpc("any_peer", "call_local")
func exit_vehicle():
	if multiplayer.is_server():
		var peer_id = multiplayer.get_remote_sender_id()
		if player_passanger and player_passanger.player_peer_id == peer_id:
			set_passanger.rpc(-1)
		if player_driver and player_driver.player_peer_id == peer_id:
			set_driver.rpc(-1)
			
@rpc("any_peer", "call_local")
func drive():
	if multiplayer.is_server():
		var peer_id = multiplayer.get_remote_sender_id()
		var p = GameState.current_world.get_player_by_peer(peer_id)
		
		if player_driver:
			if player_driver == p:
				set_driver.rpc(-1)
			return
			
		if p.vehicle_object:
			if p.vehicle_object == self and player_passanger == p:
				set_passanger.rpc(-1)
				set_driver.rpc(peer_id)
		else:
			set_driver.rpc(peer_id)

@rpc("authority", "call_local")
func set_passanger(peer_id : int):
	if player_passanger:
		player_passanger.set_vehicle(null, Transform3D.IDENTITY, false)
		remove_collision_exception_with(player_passanger)
		player_passanger = null
		
	if peer_id > 0:
		var p = GameState.current_world.get_player_by_peer(peer_id)
		if p:
			p.set_vehicle(self, passanger_seat_1.transform, false)
			player_passanger = p
			add_collision_exception_with(player_passanger)
	
@rpc("authority", "call_local")
func set_driver(peer_id : int):
	if player_driver:
		player_driver.set_vehicle(null, Transform3D.IDENTITY, false)
		remove_collision_exception_with(player_driver)
		player_driver = null
		
	if peer_id > 0:
		var p = GameState.current_world.get_player_by_peer(peer_id)
		p.set_vehicle(self, driver_seat_1.transform, true)
		player_driver = p
		add_collision_exception_with(player_driver)

@rpc("any_peer", "call_local")
func toggle_indicator_left():
	if multiplayer.is_server():
		indicator_left = not indicator_left

@rpc("any_peer", "call_local")
func toggle_indicator_right():
	if multiplayer.is_server():
		indicator_right = not indicator_right

@rpc("any_peer", "call_local")
func toggle_indicator_hazard():
	if multiplayer.is_server():
		indicator_hazard = not indicator_hazard

@rpc("any_peer", "call_local")
func toggle_handbrake():
	if multiplayer.is_server():
		handbrake = not handbrake
		
@rpc("any_peer", "call_local")
func toggle_lights():
	if multiplayer.is_server():
		lights = not lights

@rpc("any_peer", "call_local")
func toggle_highbeam():
	if multiplayer.is_server():
		highbeam = not highbeam
		
@rpc("any_peer", "call_local")
func shift_up():
	if multiplayer.is_server():
		_shift_gear(current_gear + 1)
		
@rpc("any_peer", "call_local")
func shift_down():
	if multiplayer.is_server():
		_shift_gear(current_gear - 1)
