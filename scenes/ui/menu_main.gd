extends Control

@onready var edit_server_port_1: LineEdit = $CenterContainer/VBoxContainer/EditServerPort1
@onready var edit_server_ip_2: LineEdit = $CenterContainer/VBoxContainer/EditServerIP2
@onready var edit_server_port_2: LineEdit = $CenterContainer/VBoxContainer/EditServerPort2
@onready var button_cancel: Button = $CenterContainer/VBoxContainer/ButtonCancel
@onready var button_create_server: Button = $CenterContainer/VBoxContainer/ButtonCreateServer
@onready var button_join: Button = $CenterContainer/VBoxContainer/ButtonJoin

var _wait_for_connect = false

func _ready():
	Network.state_changed.connect(_on_network_state_changed)

func _on_button_create_server_pressed() -> void:
	AudioManager.play_click()
	var host_port = int(edit_server_port_1.text)
	button_cancel.visible = true
	button_join.disabled = true
	button_create_server.disabled = true
	var err = Network.network_host(host_port)
	if err != OK:
		UI.show_error_message("Network Error", "Cannot create server.")

func _on_button_join_pressed() -> void:
	_wait_for_connect = false
	AudioManager.play_click()
	var ip = edit_server_ip_2.text
	var port = int(edit_server_port_2.text)
	
	button_cancel.visible = true
	button_join.disabled = true
	button_create_server.disabled = true
	var err = Network.network_join(ip, port)
	if err != OK:
		UI.show_error_message("Network Error", "Cannot join to server.")
	else:
		_wait_for_connect = true

func _on_button_cancel_pressed() -> void:
	_wait_for_connect = false
	AudioManager.play_click()
	Network.network_disconnect()

func _on_network_state_changed(state):
	if state == Network.NetworkState.NOT_CONNECTED:
		$CenterContainer.show()
		button_cancel.visible = false
		button_join.disabled = false
		button_create_server.disabled = false
		if _wait_for_connect:
			_wait_for_connect = false
			UI.show_error_message("Network Error", "Connection timeout.")
	elif state == Network.NetworkState.LISTENING:
		$CenterContainer.hide()
	elif state == Network.NetworkState.CONNECTED:
		$CenterContainer.hide()
		_wait_for_connect = false
