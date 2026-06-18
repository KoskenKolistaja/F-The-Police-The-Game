extends StaticBody3D

@export var building : Node3D



func on_interacted(player,hand_item):
	if hand_item:
		return
	
	var new_position = building.get_door_position()
	player.global_position = new_position




func _ready():
	await get_tree().physics_frame
	building.external_door = self

func get_door_position():
	return %DoorPosition.global_position
