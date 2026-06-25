class_name Car
extends AnimatableBody3D

@export var road : Node3D

var lane : Lane
var next_lane

var progress : float = 0.0

var speed : float = 5.0
var current_lane_speed: float = 1.0

var directions
var is_truck : bool = false
var target = null


func _ready() -> void:
	if not lane:
		lane = road.get_lane()
	
	speed = randf_range(4.0, 6.0)


func set_visuals(product : ItemData) -> void:
	var mat : StandardMaterial3D = %LogoL.get_active_material(0)
	mat.albedo_texture = product.get_logo()
	mat.albedo_color = product.get_color()


func _physics_process(delta: float) -> void:
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
		look_at(future_pos)
