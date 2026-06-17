extends Area3D


@export var parent : Node3D
@export var path_target : PathFollow3D
@export var path_target2 : PathFollow3D

func get_root():
	return parent

func get_path_target():
	var paths = [path_target,path_target2]
	
	print("GETTING?")
	print(path_target.reserved)
	
	for p in paths:
		if not p.reserved:
			print("GOT")
			return p
	
	return null

func setup_path_target(path,height):
	var real_height = height - parent.global_position.y
	path.progress = real_height
	path.reserved = true

func reset_path(path):
	path.reserved = false
