extends Node3D

@export var private_connection : bool = false





func _ready():
	if private_connection:
		%LaneNE.is_restricted = true
		%LaneSE.is_restricted = true
