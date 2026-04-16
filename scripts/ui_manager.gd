extends Node

const DIALOG_ERROR_MESSAGE = preload("res://resources/dialog_error_message.tscn")

func show_error_message(title:String, message:String):
	var dialog = DIALOG_ERROR_MESSAGE.instantiate()
	dialog.title = title
	dialog.dialog_text = message
	add_child(dialog)
	dialog.confirmed.connect(func(): dialog.queue_free() )
	dialog.popup_centered()

func _ready():
	_set_window_position(OS.get_cmdline_args())
	
func _set_window_position(args):
	var window := get_window()
	
	# Embedded window can't be moved
	if window.is_embedded():
		return
		
	var i = args.find("--window-position")
	if i < 0 or i + 1 >= args.size():
		return
		
	var parts = args[i + 1].split(",")
	if parts.size() < 2:
		return
		
	var offset := Vector2i(int(parts[0]), int(parts[1]))
	var screen_pos := DisplayServer.screen_get_position(DisplayServer.get_primary_screen())
	window.position = screen_pos + offset
