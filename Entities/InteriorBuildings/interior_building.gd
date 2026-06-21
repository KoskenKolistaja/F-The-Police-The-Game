extends Node3D

@export var external_door : Node3D
@export var internal_door : Node3D

@export var external_door2 : Node3D
@export var internal_door2 : Node3D









func teleport_player(player,door = null):
	if door == internal_door2:
		player.global_position = external_door2.get_door_position()
	else:
		player.global_position = external_door.get_door_position()

func get_door_position():
	return internal_door.get_door_position()

func get_backdoor_position():
	return internal_door2.get_door_position()
