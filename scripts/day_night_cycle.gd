extends Node
class_name DayNightCycle

const EPSILON = 0.0001

@export var directional_light_3d : DirectionalLight3D = null
@export var time_of_day := 0.3
@export var day_speed := 0.0025

func _physics_process(delta: float) -> void:
	_handle_sun(delta)

func _handle_sun(delta):
	if is_multiplayer_authority():
		var ds = day_speed
		if Input.is_action_pressed("admin_time_speedup"):
			ds = ds * 100
		time_of_day += delta * ds
		time_of_day = fmod(time_of_day, 1)
	
	var offset := TAU * 0.25
	var sun_dir = directional_light_3d.global_transform.basis.z
	
	directional_light_3d.rotation.x = remap( time_of_day * 1440 , 0, 1440, 0 + offset, TAU + offset)
	directional_light_3d.light_color = get_sun_color(sun_dir)
	directional_light_3d.visible = directional_light_3d.rotation.x > TAU * 0.3 + EPSILON and directional_light_3d.rotation.x < TAU * 1.1 - EPSILON
	
func get_sun_color(sun_direction: Vector3) -> Color:
	var elevation = clamp(sun_direction.y, -1.0, 1.0)
	var t = smoothstep(-0.2, 0.6, elevation)   
	t = pow(t, 1.5)
	var sunrise_color = Color(1.0, 0.4, 0.1)
	var noon_color = Color(1.0, 0.95, 0.85)
	var night_color = Color(0.2, 0.3, 0.5)
	if elevation > 0.0:
		return sunrise_color.lerp(noon_color, t)
	else:
		var night_t = smoothstep(-0.4, 0.0, elevation)
		return night_color.lerp(sunrise_color, night_t)
		
