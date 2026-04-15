extends Node2D
class_name MouseStateIndicator

@export var state : int = 0

func set_state(s : int):
	state = s
	queue_redraw()
	
func _draw() -> void:
	var viewport = get_viewport_rect()
	var center = viewport.get_center()
	
	if state == 1:
		draw_circle(center, 2.0, Color.RED, true, -1.0, true)
	elif state == 2:
		draw_circle(center, 2.0, Color.BLUE, true, -1.0, true)
	elif state == 3:
		draw_circle(center, 2.0, Color.ORANGE, true, -1.0, true)
	else:
		draw_circle(center, 2.0, Color.WHITE, true, -1.0, true)
	
