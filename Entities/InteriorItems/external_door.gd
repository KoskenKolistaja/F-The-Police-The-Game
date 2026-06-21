extends StaticBody3D

@export var building : Node3D
@export var is_backdoor : bool
@export var is_mafia : bool

func on_interacted(player,hand_item):
	if hand_item:
		return
	
	if is_mafia:
		if CrimeManager.get_total_crime_score(player) < 100:
			var dic = {
				"text" : "Go back to your momma!",
				"icon_name" : "mafia_boss",
				"name" : "???",
			}
			player.get_hud().add_character_message(dic)
			return
		if player.is_police():
			var dic = {
				"text" : "Get out of here!",
				"icon_name" : "mafia_boss",
				"name" : "???",
			}
			player.get_hud().add_character_message(dic)
			return
	
	var new_position
	if is_backdoor:
		new_position = building.get_backdoor_position()
	else:
		new_position = building.get_door_position()
	
	
	player.global_position = new_position




func _ready():
	await get_tree().physics_frame
	if is_backdoor:
		building.external_door2 = self
	else:
		building.external_door = self

func get_door_position():
	return %DoorPosition.global_position
