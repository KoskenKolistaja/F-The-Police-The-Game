class_name Car
extends Node3D

@export var road : Node3D
@export var min_max = 5.0
@export var max_max = 8.0


var lane : Lane
var next_lane

var progress : float = 0.0

var max_speed = 5.0
var speed : float = 5.0
var current_lane_speed: float = 1.0

var directions
var is_truck : bool = false
var target = null

var body_y = 0

var idle_time = 0.0

func _ready() -> void:
	if not lane:
		lane = road.get_lane()
	
	max_speed = randf_range(min_max, max_max)


func set_visuals(product : ItemData) -> void:
	var mat : StandardMaterial3D = %LogoL.get_active_material(0)
	mat.albedo_texture = product.get_logo()
	mat.albedo_color = product.get_color()


func _physics_process(delta: float) -> void:
	
	if not %Area3D.get_overlapping_bodies().is_empty() and not idle_time > 100.0:
		brake()
	else:
		accelerate()
	
	
	if next_lane:
		current_lane_speed = move_toward(current_lane_speed, next_lane.lane_speed, 0.01)
	
	# Reverted to your exact progress logic
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
				return 
			else:
				lane = directions[0]
	
	# 1. Set the current global position
	var pos = lane.sample_position(progress)
	global_position = pos
	
	# 2. Look ahead smoothly
	var look_ahead_distance := 1.0
	var look_progress = progress + look_ahead_distance
	var look_lane = lane
	
	var future_pos = look_lane.sample_position(look_progress)
	
	
	# 3. Orient the car
	if global_position.distance_squared_to(future_pos) > 0.001:
		var target_basis := Transform3D(global_transform.basis, global_position).looking_at(future_pos).basis
		global_transform.basis = global_transform.basis.slerp(target_basis, delta * 8.0)
	
	%AnimatableBody3D.position = Vector3.ZERO

func brake():
	speed = move_toward(speed,0.0,0.2)
	idle_time = move_toward(idle_time,200.0,0.03)

func accelerate():
	speed = move_toward(speed,max_speed,0.1)
	idle_time = move_toward(idle_time,0.0,0.01)
