extends Control

@onready var label_fps: Label = $MarginContainer/MarginContainer/VBoxContainer/LabelFPS
@onready var label_network: Label = $MarginContainer/MarginContainer/VBoxContainer/LabelNetwork

func _ready():
	update_peers()

func _process(_delta: float):
	label_fps.text = "FPS: %d" % Engine.get_frames_per_second()
	
func update_peers():
	var peer = multiplayer.get_multiplayer_peer()
	if peer != null and is_instance_valid(peer) and peer is ENetMultiplayerPeer:
		var peers = multiplayer.get_peers()
		var enet_peer = peer as ENetMultiplayerPeer
		var enet_host = enet_peer.host
		if enet_host:
			var total_received_data = enet_host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA)
			var total_sent_data = enet_host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
			
			label_network.text = "In: %d Kb, Out: %d Kb (%s, peers: %s, hosts: %s)" % [
				total_received_data / 1024.0,  total_sent_data / 1024.0, 
				"server" if multiplayer.is_server() else "client", peers.size(), enet_host.get_peers().size()]
	
			return
	
	label_network.text = "In: 0 Kb, Out: 0 Kb (unknow)"
