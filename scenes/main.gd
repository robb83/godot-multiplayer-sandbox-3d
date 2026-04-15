extends Node

const MAP_001 = preload("res://scenes/levels/map_001.tscn")

@onready var levels: Node = $Levels
@onready var options: Control = $Options
@onready var main_menu: Control = $MainMenu
@onready var menu_statistics: Control = $MenuStatistics

var current_map = null

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
		if current_map:
			levels.remove_child(current_map)
			current_map = null
	elif state == Network.NetworkState.LISTENING:
		menu_statistics.show()
		main_menu.hide()
		current_map = MAP_001.instantiate()
		levels.add_child(current_map)
		add_player(1)
		for id in multiplayer.get_peers():
			current_map.add_player(id)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif state == Network.NetworkState.CONNECTED:
		menu_statistics.show()
		main_menu.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func add_player(id: int):
	if current_map:
		current_map.add_player(id)

func del_player(id: int):
	if current_map:
		current_map.del_player(id)
