extends Node

var players_to_arrest = []



var game_over = false




func arrest(player):
	print("ATTEMPTED ARREST")
	if players_to_arrest.has(player):
		players_to_arrest.erase(player)
	
	if players_to_arrest.is_empty() and not game_over:
		police_win()
		game_over = true
		await get_tree().create_timer(10).timeout
		game_over = false
		get_tree().reload_current_scene()
	
	

func police_win():
	print("THE POLICE WON THE GAME!")
