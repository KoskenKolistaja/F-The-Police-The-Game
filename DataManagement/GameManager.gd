extends Node

var players_to_arrest = []








func arrest(player):
	if players_to_arrest.has(player):
		players_to_arrest.erase(player)
	
	if players_to_arrest.is_empty():
		police_win()
		


func police_win():
	print("THE POLICE WON THE GAME!")
