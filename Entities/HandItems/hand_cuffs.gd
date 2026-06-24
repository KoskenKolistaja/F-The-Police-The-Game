extends Node3D

var player_character

func use():
	pass

func use2():
	pass

func set_visual_layer(layer : int,on : bool):
	%HandCuffs.set_layer_mask_value(layer,on)
