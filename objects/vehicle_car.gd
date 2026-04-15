extends VehicleBody3D

@onready var driver_seat_1: Node3D = $Seats/DriverSeat1
@onready var passanger_seat_1: Node3D = $Seats/PassangerSeat1

func _ready():
	driver_seat_1.set_meta('object', self)
	passanger_seat_1.set_meta('object', self)

@rpc("any_peer", "call_local")
func _kick():
	Network.network_kick(multiplayer.get_remote_sender_id())

func interact(player):
	_kick.rpc_id(1)

func drive(player):
	_kick.rpc_id(1)
