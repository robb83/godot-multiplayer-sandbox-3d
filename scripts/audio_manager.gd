extends Node

const MOUSECLICK_1 = preload("res://assets/kenney_ui_audio/Audio/mouseclick1.ogg")

func play_click():
	var p = AudioStreamPlayer.new()
	p.stream = MOUSECLICK_1
	p.bus = &"UI"
	add_child(p)
	p.play()
	p.finished.connect(func(): p.queue_free())
