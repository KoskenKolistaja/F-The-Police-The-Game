extends Node3D

@export var target : Node3D
@export var player_root : Node3D

var height_layer = 0

func show_metro():
	var new_layer = 0
	if new_layer == height_layer:
		return
	
	%Camera.set_cull_mask_value(3,true)
	%Camera.set_cull_mask_value(2,false)
	
	height_layer = new_layer

func show_upper():
	var new_layer = 2
	if new_layer == height_layer:
		return
	
	%Camera.set_cull_mask_value(3,false)
	%Camera.set_cull_mask_value(2,true)
	
	height_layer = new_layer




func _physics_process(delta):
	global_position = target.global_position
	
	
	var player_id = player_root.player_id
	
	var axis = Input.get_joy_axis(player_id,JOY_AXIS_RIGHT_X)
	
	if abs(axis) < 0.2:
		axis = 0.0
	
	rotation_degrees.y -= axis


func set_police():
	%Camera.set_cull_mask_value(15,true)
