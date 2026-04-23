extends Control

@onready var button_disconnect: Button = $MarginContainer/VBoxContainer/MarginContainer/ButtonDisconnect

func _process(_delta):
	button_disconnect.visible = GameState.current_world != null
	
func _on_button_disconnect_pressed() -> void:
	AudioManager.play_click()
	Network.network_disconnect()
