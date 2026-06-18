extends Node3D

@export var external_door : Node3D
@export var internal_door : Node3D








func teleport_player(player):
	player.global_position = external_door.get_door_position()

func get_door_position():
	return internal_door.get_door_position()
