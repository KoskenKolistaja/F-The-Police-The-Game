extends Area3D


@export var parent : Node3D
@export var path_target : PathFollow3D

func get_root():
	return parent

func get_path_target():
	return path_target

func setup_path_target(height):
	var real_height = height - parent.global_position.y
	path_target.progress = real_height
