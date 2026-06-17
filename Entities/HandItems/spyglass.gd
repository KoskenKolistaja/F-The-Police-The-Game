extends Node3D

var player_character = null



func use():
	var npcs = %Area3D.get_overlapping_bodies()
	for npc in npcs:
		npc.investigate(player_character)
	
	var items = %Area3D.get_overlapping_bodies()
	for item in items:
		item.investigate(player_character)

func use2():
	pass
