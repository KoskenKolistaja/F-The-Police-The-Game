extends StaticBody3D

@export var building : Node3D






func get_door_position():
	return %DoorPosition.global_position


func on_interacted(player,hand_item):
	building.teleport_player(player)
