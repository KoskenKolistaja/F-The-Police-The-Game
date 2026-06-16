extends Node3D

@export var exporting_building : Node3D
@export var importing_building : Node3D





func get_end_lane():
	return %LaneBackward

func get_start_lane():
	return %LaneForward
