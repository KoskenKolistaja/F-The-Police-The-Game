class_name Car
extends Node3D

@export var road : Node3D
var lane : Lane

var next_lane

var progress : float = 0.0

var speed : float = 5.0
var current_lane_speed = 1.0

var directions

var is_truck : bool = false


var target = null


func _ready():
	if not lane:
		lane = road.get_lane()
	speed = randf_range(4,6)
	
	
	
	
	
	
	




func set_visuals(product : ItemData) -> void:
	var mat : StandardMaterial3D = %LogoL.get_active_material(0)
	mat.albedo_texture = product.get_logo()
	mat.albedo_color = product.get_color()





func _physics_process(delta):
	
	if next_lane:
		current_lane_speed = move_toward(current_lane_speed,next_lane.lane_speed,0.01)
	
	progress += speed * delta
	
	# Handle moving to the next lane
	if progress >= lane.length:
		
		progress -= lane.length
		if not directions:
			var new_lane = lane.get_next_lane(self)
			lane = new_lane
			next_lane = lane.get_next_lane(self)
		else:
			directions.remove_at(0)
			if directions.is_empty():
				queue_free()
			else:
				lane = directions[0]
	
	# 1. Set the current global position
	var pos = lane.sample_position(progress)
	global_position = pos
	
	# 2. Look ahead smoothly (even previewing the next lane!)
	var look_ahead_distance = 1.0
	var look_progress = progress + look_ahead_distance
	var look_lane = lane
	
	#if look_progress >= look_lane.length:
		#look_progress -= look_lane.length
		#look_lane = look_lane.get_next_lane()
		#
	var future_pos = look_lane.sample_position(look_progress)
	
	# 3. Tell look_at where to aim in world space
	if global_position.distance_squared_to(future_pos) > 0.001:
		look_at(future_pos)
	
	follow_target(%RigidBody,%Mesh)

func follow_target(body: RigidBody3D, target: Node3D):
	# Position
	var pos_error = target.global_position - body.global_position

	body.apply_central_force(
		(pos_error * 50.0 - body.linear_velocity * 10.0) * body.mass
	)

	# Rotation
	var current_q = body.global_basis.get_rotation_quaternion()
	var target_q = target.global_basis.get_rotation_quaternion()

	var delta_q = current_q.inverse() * target_q

	var axis = Vector3(delta_q.x, delta_q.y, delta_q.z)
	if axis.length() > 0.001:
		axis = axis.normalized()

		var angle = 2.0 * acos(clamp(delta_q.w, -1.0, 1.0))

		if angle > PI:
			angle -= TAU

		body.apply_torque(
			(axis * angle * 30.0 - body.angular_velocity * 8.0) * body.mass
		)
