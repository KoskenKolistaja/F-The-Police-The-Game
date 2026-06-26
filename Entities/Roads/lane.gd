class_name Lane
extends Node3D

@export var path : Path3D
@onready var curve : Curve3D = path.curve
var next_lanes : Array[Lane] = []
@export var lane_speed = 1.0
@onready var length = curve.get_baked_length()
@export var is_restricted : bool = false
@export var building : Node3D
@export var in_socket : Node3D
@export var out_socket : Node3D



var id = null

func _ready():
	var in_sockets = get_tree().get_nodes_in_group("in_socket")
	
	await get_tree().create_timer(0.1).timeout
	
	for in_socket in in_sockets:
		var distance = (out_socket.global_position - in_socket.global_position).length()
		if distance < 0.01:
			if in_socket.get_lane().is_restricted:
				continue
			
			next_lanes.append(in_socket.get_lane())
	
	await get_tree().physics_frame
	id = TrafficManager.get_id()
	await get_tree().physics_frame
	#var label_3D = Label3D.new()
	#add_child(label_3D)
	#label_3D.global_position = self.global_position + Vector3.UP
	#if not next_lanes.is_empty():
		#label_3D.text = "ID: " + str(id) + " NEXT ID: " + str(next_lanes[0].id)
	#label_3D.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	#label_3D.font_size = 64
	
	#var ball_instance = debug_ball.instantiate()
	#add_child(ball_instance)
	#ball_instance.global_transform = sample_global_transform(1.5)
	#ball_instance.global_position += Vector3(randf_range(-0.2,0.2),randf_range(-0.2,0.2),randf_range(-0.2,0.2))





func get_next_lane(caller) -> Lane:
	if next_lanes.is_empty():
		if building:
			caller.queue_free()
			return self
		else:
			return self
	else:
		
		
		return next_lanes.pick_random()

func sample_position(distance : float) -> Vector3:
	var local_pos = curve.sample_baked(distance)
	return path.global_transform * local_pos

#func sample_position(distance : float) -> Vector3:
	#var local_pos = curve.sample_baked(distance)
	#return path.to_global(local_pos)


func sample_forward(distance : float) -> Vector3:
	var local_forward = curve.sample_baked(min(distance + 1.0, length))
	return path.global_transform * local_forward

func sample_global_transform(distance : float) -> Transform3D:
	# 1. Get the full local position and rotation matrix from the curve
	var local_transform = curve.sample_baked_with_rotation(distance, true)
	
	# 2. Combine it with the path's world transform to make it global
	return path.global_transform * local_transform
