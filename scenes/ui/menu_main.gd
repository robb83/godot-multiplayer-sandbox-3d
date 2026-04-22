extends Control

@onready var edit_server_port_1: LineEdit = $CenterContainer/VBoxContainer/EditServerPort1
@onready var edit_server_ip_2: LineEdit = $CenterContainer/VBoxContainer/EditServerIP2
@onready var edit_server_port_2: LineEdit = $CenterContainer/VBoxContainer/EditServerPort2
@onready var button_cancel: Button = $CenterContainer/VBoxContainer/ButtonCancel
@onready var button_create_server: Button = $CenterContainer/VBoxContainer/ButtonCreateServer
@onready var button_join: Button = $CenterContainer/VBoxContainer/ButtonJoin
@onready var option_worlds: OptionButton = $CenterContainer/VBoxContainer/OptionWorlds

var wait_for_connect = false
var selectable_worlds = []

func _ready():
	_populate_options()
	Network.state_changed.connect(_on_network_state_changed)

func _populate_options():
	selectable_worlds = GameState.get_worlds()
	option_worlds.clear()
	for world in selectable_worlds:
		option_worlds.add_item(world.name)
	
func _on_button_create_server_pressed() -> void:
	AudioManager.play_click()
	var selected = option_worlds.get_selected_id()
	if selected < 0 or selected >= selectable_worlds.size():
		UI.show_error_message("Error", "No World selected.")
		return
	GameState.selected_world = selectable_worlds[selected]
	var host_port = int(edit_server_port_1.text)
	button_cancel.visible = true
	button_join.disabled = true
	button_create_server.disabled = true
	option_worlds.disabled = true
	var err = Network.network_host(host_port)
	if err != OK:
		UI.show_error_message("Network Error", "Cannot create server.")

func _on_button_join_pressed() -> void:
	wait_for_connect = false
	AudioManager.play_click()
	var ip = edit_server_ip_2.text
	var port = int(edit_server_port_2.text)
	
	button_cancel.visible = true
	button_join.disabled = true
	button_create_server.disabled = true
	option_worlds.disabled = true
	
	var err = Network.network_join(ip, port)
	if err != OK:
		UI.show_error_message("Network Error", "Cannot join to server.")
	else:
		wait_for_connect = true

func _on_button_cancel_pressed() -> void:
	wait_for_connect = false
	AudioManager.play_click()
	Network.network_disconnect()

func _on_network_state_changed(state):
	if state == Network.NetworkState.NOT_CONNECTED:
		$CenterContainer.show()
		button_cancel.visible = false
		button_join.disabled = false
		button_create_server.disabled = false
		option_worlds.disabled = false
		if wait_for_connect:
			wait_for_connect = false
			UI.show_error_message("Network Error", "Connection timeout.")
	elif state == Network.NetworkState.LISTENING:
		$CenterContainer.hide()
	elif state == Network.NetworkState.CONNECTED:
		$CenterContainer.hide()
		wait_for_connect = false
