#socket.gd
extends Node3D



@export var lane : Lane

func get_lane():
	return lane



func _ready():
	hide()
