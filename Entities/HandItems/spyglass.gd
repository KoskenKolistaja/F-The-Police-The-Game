extends Node3D

var player_character = null



func use():
	var npcs = %Area3D.get_overlapping_bodies()
	for npc in npcs:
		npc.investigate(player_character)
	
	var items = %Area3D2.get_overlapping_bodies()
	for item in items:
		item.investigate(player_character)

func use2():
	pass

func set_visual_layer(layer : int,on : bool):
	%Spyglass.set_layer_mask_value(layer,on)
