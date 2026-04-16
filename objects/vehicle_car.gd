extends VehicleBody3D

@onready var driver_seat_1: Node3D = $Seats/DriverSeat1
@onready var passanger_seat_1: Node3D = $Seats/PassangerSeat1

func _ready():
	driver_seat_1.set_meta('object', self)
	passanger_seat_1.set_meta('object', self)

@rpc("any_peer", "call_local")
func interact():
	Network.network_kick(multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_local")
func drive(_player):
	Network.network_kick(multiplayer.get_remote_sender_id())
