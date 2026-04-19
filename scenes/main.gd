extends Node

@onready var worlds: Node = $Worlds
@onready var menu_options: Control = $MenuOptions
@onready var main_menu: Control = $MainMenu

var current_peer_id := -1

func _ready():
	Network.state_changed.connect(_on_network_state_changed)
	Network.player_connected.connect(add_player)
	Network.player_disconnected.connect(del_player)

func _input(_event: InputEvent) -> void:
	if Network.state != Network.NetworkState.NOT_CONNECTED and Input.is_action_just_pressed("menu"):
		menu_options.visible = not menu_options.visible
		if menu_options.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _process(_delta: float) -> void:
	GameState.menu_visible = menu_options.visible or main_menu.visible
	
func _on_network_state_changed(state):
	if state == Network.NetworkState.NOT_CONNECTED:
		current_peer_id = -1
		menu_options.hide()
		main_menu.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if GameState.current_world:
			#Clear GameState.current_world
			worlds.remove_child(GameState.current_world)
	elif state == Network.NetworkState.LISTENING:
		current_peer_id = multiplayer.get_unique_id()
		main_menu.hide()
		#Set GameState.current_world
		if GameState.selected_world:
			var world_scene = load(GameState.selected_world.path)
			worlds.add_child(world_scene.instantiate())
		else:
			Network.network_disconnect()
	elif state == Network.NetworkState.CONNECTED:
		current_peer_id = multiplayer.get_unique_id()
		main_menu.hide()

func add_player(id: int):
	if multiplayer.is_server():
		if GameState.current_world:
			GameState.current_world.add_player(id)

func del_player(id: int):
	if multiplayer.is_server():
		if GameState.current_world:
			GameState.current_world.del_player(id)
