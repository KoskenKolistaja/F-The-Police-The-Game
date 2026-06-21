extends StaticBody3D

var player_inside = null
var cannot_enter = false

var enter_position = null

func on_interacted(player,hand_item):
	if cannot_enter:
		return
	
	if hand_item:
		return
	
	if not player_inside:
		player_inside = player
		enter_position = player.global_position
		var player_root = player.get_player_root()
		player_root.set_player_driver(self)
	else:
		if is_instance_valid(player_inside):
			player_inside.get_player_root().exit_vehicle(get_exit_position())
			player_exited()


func get_exit_position():
	if enter_position:
		return enter_position
	else:
		return %ExitPosition.global_position


func player_exited():
	player_inside = null
	cannot_enter = true
	enter_position = null
	await get_tree().create_timer(5.0).timeout
	cannot_enter = false
