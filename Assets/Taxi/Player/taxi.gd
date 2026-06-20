extends Node3D


@onready var ball = $Ball
@onready var car_mesh = $taxi_mesh
@onready var ground_ray = $taxi_mesh/RayCast3D

@export var damage_label: PackedScene

@export var smoke1: GPUParticles3D
@export var smoke2: GPUParticles3D

var cannot_enter = false
var player_inside = false

var illegalities = []

var hp = 100

var max_speed = 100

var sphere_offset = Vector3(0,-0.5,0)
var acceleration  = 25
var steering = 21.0
var turn_speed = 5
var turn_stop_limit = 1

var speed_input = 0
var rotate_input = 0

var offset

var hand_brake_ratio = 1.0
var drift = 1

var speed_meter = 0

var stopped = false

var handbrake = true


var doors

func _ready():
	
	doors = [$taxi_mesh/left_door,$taxi_mesh/right_door]
	
	ground_ray.add_exception(ball)
	

	
	#check_stats()
	

#func check_stats():
	#if MetaData.turbo:
		#acceleration = 21.5
		#max_speed = 1000
	#elif MetaData.large:
		#acceleration = 21
		#max_speed = 70
	#elif MetaData.medium:
		#acceleration = 20.5
		#max_speed = 60
	#else:
		#acceleration = 20
		#max_speed = 50
	#
	#if MetaData.lights:
		#$taxi_mesh/car_taxi/SpotLight3D.show()
		#$taxi_mesh/car_taxi/SpotLight3D2.show()
	#
	#if MetaData.handbrake:
		#handbrake = true

func _physics_process(delta):
	
	if not stopped:
		handle_input_and_movement(delta)
	$ThrottleSound.pitch_scale = 1 + (ball.linear_velocity.length())
	
	
	
	

#From 0 to 1.0
func accelerate(amount):
	speed_input -= amount

#From 0 to 1.0
func brake(amount):
	speed_input += amount

#From -1 to 1
func steer(amount):
	rotate_input += amount


func handle_input_and_movement(delta):
	
	speed_meter = ball.get_speed()
	
	
	$taxi_mesh/Label3D.text = str(illegalities)
	
	
	car_mesh.global_transform.origin = ball.global_position + sphere_offset
	
	if speed_meter < max_speed:
		ball.apply_force(-car_mesh.global_transform.basis.z * speed_input * hand_brake_ratio)
	else:
		ball.apply_force(-car_mesh.global_transform.basis.z * speed_input/2 * hand_brake_ratio)

	
	var current_y = $taxi_mesh/CameraPivot.rotation_degrees.y
	var target_y = $taxi_mesh.rotation_degrees.y

	# Get the shortest signed angle difference
	var angle_diff = fposmod((target_y - current_y) + 180, 360) - 180
	$taxi_mesh/CameraPivot.global_position = car_mesh.global_position
	
	#$taxi_mesh/CameraPivot.rotation_degrees.y = move_toward($taxi_mesh/CameraPivot.rotation_degrees.y,$taxi_mesh.rotation_degrees.y,abs($taxi_mesh/CameraPivot.rotation_degrees.y-$taxi_mesh.rotation_degrees.y)/10)
	$taxi_mesh/CameraPivot.rotation_degrees.y += move_toward(0, angle_diff, abs(angle_diff) / 30)
	#if not ground_ray.is_colliding():
		#return
	
	
	speed_input = 0
	speed_input -= Input.get_action_strength("accelerate")
	speed_input += Input.get_action_strength("brake")
	speed_input *= acceleration
	
	var desired = 75 + (ball.linear_velocity.length() *4)
	
	$taxi_mesh/CameraPivot/Camera3D.fov = move_toward($taxi_mesh/CameraPivot/Camera3D.fov,desired,0.1)
	
	
	
	
	rotate_input = 0
	
	if abs(Input.get_joy_axis(0,JOY_AXIS_LEFT_X)) > 0.2:
		rotate_input -= Input.get_joy_axis(0,JOY_AXIS_LEFT_X)
		rotate_input *= deg_to_rad(steering)
		if ball.linear_velocity.length() > 1:
			$taxi_mesh/car_taxi.rotation_degrees.z = move_toward($taxi_mesh/car_taxi.rotation_degrees.z,0 + (rotate_input*20),1)
		else:
			$taxi_mesh/car_taxi.rotation_degrees.z = move_toward($taxi_mesh/car_taxi.rotation_degrees.z,0,1)
			
	else:
		
		$taxi_mesh/car_taxi.rotation_degrees.z = move_toward($taxi_mesh/car_taxi.rotation_degrees.z,0,1)
	
	
	
	if abs(speed_input) > 0.2:
		if not $ThrottleSound.is_playing():
			$ThrottleSound.play()
	
	
	
	if Input.is_action_just_pressed("handbrake") and handbrake:
		activate_smoke()
		drift = 1.5
	if Input.is_action_just_released("handbrake") and handbrake:
		deactivate_smoke()
	
	if Input.is_action_pressed("handbrake") and handbrake:
		hand_brake_ratio = move_toward(hand_brake_ratio, 0.9,0.01)
		drift = move_toward(drift,2.5,0.01)
	else:
		hand_brake_ratio = move_toward(hand_brake_ratio,1.0,0.1)
		drift = 1
	
	
	
	if ball.linear_velocity.length() > turn_stop_limit:
		var new_basis = car_mesh.global_transform.basis.rotated(car_mesh.global_transform.basis.y,
		rotate_input/1.5*drift)
		car_mesh.global_transform.basis = car_mesh.global_transform.basis.slerp(new_basis,
		turn_speed * delta)
		car_mesh.global_transform = car_mesh.global_transform.orthonormalized()
	else:
		deactivate_smoke()

func stop(): #Called from other nodes
	stopped = true
	deactivate_smoke()
	$ThrottleSound.stop()

func activate_smoke():
	smoke1.emitting = true
	smoke2.emitting = true
	if not $BrakeSound.is_playing():
		$BrakeSound.pitch_scale = 0.7 + (ball.linear_velocity.length()/10)
		$BrakeSound.play()

func deactivate_smoke():
	smoke1.emitting = false
	smoke2.emitting = false
	$BrakeSound.stop()





func get_exit_position():
	return %ExitPosition.global_position






func take_damage(amount: float = 0):
	#amount *= 5
	#amount = round(amount)
	#
	#hp -= amount
	#
	#if hp < 30:
		#$taxi_mesh/smoke_engine.emitting = true
	
	if hp <= 0:
		stop()
	
	
	#var label_instance = damage_label.instantiate()
	#label_instance.text = "-" + str(amount)
	#$taxi_mesh.add_child(label_instance)


func _on_bump_area_body_entered(body):
	if body.has_method("ragdoll"):
		body.ragdoll(ball.linear_velocity)
