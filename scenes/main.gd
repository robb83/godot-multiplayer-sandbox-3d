extends Node

@onready var worlds: Node = $Worlds
@onready var menu_options: Control = $MenuOptions
@onready var main_menu: Control = $MainMenu
@onready var menu_loading: Control = $MenuLoading

var current_peer_id := -1
var loading_scene = null

func _ready():
	Network.state_changed.connect(_on_network_state_changed)
	Network.peer_connected.connect(_peer_connected)

func _input(_event: InputEvent) -> void:
	if Network.state != Network.NetworkState.NOT_CONNECTED and Input.is_action_just_pressed("menu") and not menu_loading.visible:
		menu_options.visible = not menu_options.visible
		if menu_options.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _process(_delta: float) -> void:
	GameState.menu_visible = menu_options.visible or main_menu.visible or menu_loading.visible
	
	if loading_scene:
		var scene_path = loading_scene
		
		if Network.NetworkState.NOT_CONNECTED:
			menu_loading.hide()
			loading_scene = null
			return
		
		var status = ResourceLoader.load_threaded_get_status(scene_path)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				loading_scene = null
				var packed_scene = ResourceLoader.load_threaded_get(scene_path)
				worlds.add_child(packed_scene.instantiate())
				menu_loading.hide()
			ResourceLoader.THREAD_LOAD_FAILED:
				loading_scene = null
				menu_loading.hide()
				Network.network_disconnect()
				printerr("FAILED")
	
func _on_network_state_changed(state):
	if state == Network.NetworkState.NOT_CONNECTED:
		current_peer_id = -1
		menu_options.hide()
		main_menu.show()
		menu_loading.hide()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameState.reset()
	elif state == Network.NetworkState.LISTENING:
		current_peer_id = multiplayer.get_unique_id()
		main_menu.hide()
		#Set GameState.current_world
		if GameState.selected_world:
			menu_loading.show()
			load_world.rpc(GameState.selected_world.path)
		else:
			Network.network_disconnect()
	elif state == Network.NetworkState.CONNECTED:
		current_peer_id = multiplayer.get_unique_id()
		menu_loading.show()
		main_menu.hide()

func _peer_connected(id: int):
	if multiplayer.is_server():
		load_world.rpc_id(id, GameState.selected_world.path)

@rpc("authority", "call_local")
func load_world(scene):
	print("[%s]: load_world: %s" % [multiplayer.get_unique_id(), scene])
	
	var err = ResourceLoader.load_threaded_request(scene)
	if err == OK:
		loading_scene = scene
	else:
		printerr(err)
		Network.network_disconnect()
