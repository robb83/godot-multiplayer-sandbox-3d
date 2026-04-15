extends Node

const DIALOG_ERROR_MESSAGE = preload("res://resources/dialog_error_message.tscn")

func show_error_message(title:String, message:String):
	var dialog = DIALOG_ERROR_MESSAGE.instantiate()
	dialog.title = title
	dialog.dialog_text = message
	add_child(dialog)
	dialog.confirmed.connect(func(): dialog.queue_free() )
	dialog.popup_centered()
