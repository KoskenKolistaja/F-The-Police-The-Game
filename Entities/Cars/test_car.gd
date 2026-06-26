class_name Car
extends Node3D

@export var road : Node3D
@export var min_max = 5.0
@export var max_max = 8.0

var lane : Lane
var next_lane # Cached next lane for look-ahead & speed transitions

var progress : float = 0.0

var max_speed = 5.0
var speed : float = 5.0
var current_lane_speed: float = 1.0

var directions
var is_truck : bool = false
var target = null

var body_y = 0
var idle_time = 0.0
var lane_speed_ratio = 1.0


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
	
	# Continuously handle look-ahead caching
	if next_lane == null or next_lane == lane:
		_update_next_lane()
	
	# --- SMOOTH SPEED TRANSITION LOGIC ---
	var target_lane_speed = lane.lane_speed
	
	if next_lane and next_lane != lane:
		var remaining_dist = lane.length - progress
		
		# FIX 1: Only blend ahead if the next lane is SLOWER (Anticipatory braking).
		# If the next lane is faster, we keep target_lane_speed equal to our current slow lane.
		if next_lane.lane_speed < lane.lane_speed:
			var blend_distance = clamp(speed * 1.2, 3.0, 6.0)
			if remaining_dist < blend_distance:
				var weight = 1.0 - (remaining_dist / blend_distance)
				target_lane_speed = lerp(lane.lane_speed, next_lane.lane_speed, clamp(weight, 0.0, 1.0))
	
	# FIX 2: Asymmetric acceleration rate.
	# Slowing down happens fast (4.0) for safety, but speeding up happens gradually (1.2).
	var transition_rate = 1.2 if target_lane_speed > lane_speed_ratio else 4.0
	lane_speed_ratio = move_toward(lane_speed_ratio, target_lane_speed, delta * transition_rate)
	# --------------------------------------
	
	# Progress logic
	progress += speed * delta * lane_speed_ratio
	
	# Handle moving to the next lane
	if progress >= lane.length:
		progress -= lane.length
		
		if not directions:
			if next_lane and next_lane != lane:
				lane = next_lane
			else:
				var new_lane = lane.get_next_lane(self)
				if new_lane == lane: 
					return 
				lane = new_lane
			
			next_lane = null 
		else:
			directions.remove_at(0)
			if directions.is_empty():
				queue_free()
				return 
			else:
				lane = directions[0]
				next_lane = null
	
	# 1. Set the current global position
	var pos = lane.sample_position(progress)
	global_position = pos
	
	# 2. Look ahead smoothly and sample across boundaries accurately
	var look_ahead_distance := 1.0
	var look_progress = progress + look_ahead_distance
	var future_pos : Vector3
	
	if look_progress > lane.length and next_lane and next_lane != lane:
		var leftover_dist = look_progress - lane.length
		future_pos = next_lane.sample_position(leftover_dist)
	else:
		future_pos = lane.sample_position(look_progress)
	
	# 3. Orient the car
	if global_position.distance_squared_to(future_pos) > 0.001:
		var target_basis := Transform3D(global_transform.basis, global_position).looking_at(future_pos).basis
		global_transform.basis = global_transform.basis.slerp(target_basis, delta * 8.0)
	
	%AnimatableBody3D.position = Vector3.ZERO


func _update_next_lane() -> void:
	if not directions:
		var fetched = lane.get_next_lane(self)
		if fetched != lane:
			next_lane = fetched
	else:
		if directions.size() > 1:
			next_lane = directions[1]
		else:
			next_lane = null


func brake():
	speed = move_toward(speed, 0.0, 0.2)
	idle_time = move_toward(idle_time, 200.0, 0.03)


func accelerate():
	speed = move_toward(speed, max_speed, 0.1)
	idle_time = move_toward(idle_time, 0.0, 0.01)
