extends Control

func _on_button_disconnect_pressed() -> void:
	Network.network_disconnect()
