extends Control

func _on_button_disconnect_pressed() -> void:
	AudioManager.play_click()
	Network.network_disconnect()
