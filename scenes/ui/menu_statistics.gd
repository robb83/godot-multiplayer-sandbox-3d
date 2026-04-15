extends Control

@onready var peer_list: ItemList = $VBoxContainer/ItemListPeers
@onready var label_statistics: Label = $VBoxContainer/LabelStatistics

func _ready():
	update_peers()

func update_peers():	
	var peer = multiplayer.get_multiplayer_peer()
	if peer != null and is_instance_valid(peer) and peer is ENetMultiplayerPeer:
		var enet_peer = peer as ENetMultiplayerPeer
		var enet_host = enet_peer.host
		if enet_host:
			var total_received_packets = enet_host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_PACKETS)
			var total_received_data = enet_host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA)
			
			var total_sent_packets = enet_host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_PACKETS)
			var total_sent_data = enet_host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
			
			label_statistics.text = "In: %d p / %d byte, Out: %d p / %d byte (%s)" % [
				total_received_packets, total_received_data, 
				total_sent_packets, total_sent_data, 
				"server" if multiplayer.is_server() else "client"]
	
			peer_list.clear()
			for connection in enet_host.get_peers():
				if connection:
					var ip = connection.get_remote_address()
					var ping = connection.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
					var packet_loss = connection.get_statistic(ENetPacketPeer.PEER_PACKET_LOSS)
					
					var text = "ID: %d | %s | Ping: %d ms | Loss: %.2f%%" % [ 0, ip, ping, packet_loss ]
					peer_list.add_item(text, null, false)
			return
	
	peer_list.clear()
	label_statistics.text = "In: 0 p / 0 byte, Out: 0 p / 0 byte (unknow)"
