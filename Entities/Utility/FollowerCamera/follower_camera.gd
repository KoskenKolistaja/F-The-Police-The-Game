extends Node3D

@export var target : Node3D
@export var player_root : Node3D

var showing_metro = false

func show_metro():
	if showing_metro:
		return
	
	%Camera.set_cull_mask_value(3,true)
	%Camera.set_cull_mask_value(2,false)
	
	showing_metro = true

func show_upper():
	if not showing_metro:
		return
	
	%Camera.set_cull_mask_value(3,false)
	%Camera.set_cull_mask_value(2,true)
	
	showing_metro = false




func _physics_process(delta):
	global_position = target.global_position
	
	
	var player_id = player_root.player_id
	
	var axis = Input.get_joy_axis(player_id,JOY_AXIS_RIGHT_X)
	
	if abs(axis) < 0.2:
		axis = 0.0
	
	rotation_degrees.y -= axis


func set_police():
	%Camera.set_cull_mask_value(15,true)
