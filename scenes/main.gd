extends Node

const MAP_001 = preload("res://scenes/levels/map_001.tscn")

@onready var levels: Node = $Levels
@onready var options: Control = $Options
@onready var main_menu: Control = $MainMenu
@onready var menu_statistics: Control = $MenuStatistics

func _ready():
	Network.state_changed.connect(_on_network_state_changed)
	Network.player_connected.connect(add_player)
	Network.player_disconnected.connect(del_player)

func _input(_event: InputEvent) -> void:
	if Network.state != Network.NetworkState.NOT_CONNECTED and Input.is_action_just_pressed("menu"):
		options.visible = not options.visible
		if options.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _process(_delta: float) -> void:
	GameState.menu_visible = options.visible or main_menu.visible
	
func _on_network_state_changed(state):
	if state == Network.NetworkState.NOT_CONNECTED:
		options.hide()
		menu_statistics.hide()
		main_menu.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if GameState.current_world:
			#Clear GameState.current_world
			levels.remove_child(GameState.current_world)
	elif state == Network.NetworkState.LISTENING:
		menu_statistics.show()
		main_menu.hide()
		#Set GameState.current_world
		levels.add_child(MAP_001.instantiate())
		if GameState.current_world:
			add_player(1)
			for id in multiplayer.get_peers():
				GameState.current_world.add_player(id)
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif state == Network.NetworkState.CONNECTED:
		menu_statistics.show()
		main_menu.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func add_player(id: int):
	if GameState.current_world:
		GameState.current_world.add_player(id)

func del_player(id: int):
	if GameState.current_world:
		GameState.current_world.del_player(id)
