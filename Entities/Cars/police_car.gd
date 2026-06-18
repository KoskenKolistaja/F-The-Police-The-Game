extends CharacterBody3D

var player_inside = null
var cannot_enter = false

@export var max_speed := 20.0
@export var reverse_speed := 8.0
@export var acceleration := 15.0
@export var brake_force := 25.0
@export var friction := 8.0
@export var steering_speed := 2.5

var throttle_input := 0.0
var steering_input := 0.0
var current_speed := 0.0


func _physics_process(delta):
	# Only drive when occupied
	if player_inside:
		_drive(delta)

	move_and_slide()


func _drive(delta):
	# Acceleration / braking
	if throttle_input > 0.0:
		current_speed += acceleration * throttle_input * delta
	elif throttle_input < 0.0:
		current_speed += brake_force * throttle_input * delta
	else:
		current_speed = move_toward(current_speed, 0.0, friction * delta)

	current_speed = clamp(
		current_speed,
		-reverse_speed,
		max_speed
	)

	# Steering strength increases with speed
	var steering_strength = abs(current_speed / max_speed)

	if abs(current_speed) > 0.1:
		rotate_y(
			-steering_input *
			steering_speed *
			steering_strength *
			delta
		)

	var forward = -transform.basis.z

	velocity.x = forward.x * current_speed
	velocity.z = forward.z * current_speed

	# Keep gravity working if car can leave the ground
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting(
			"physics/3d/default_gravity"
		) * delta
	else:
		velocity.y = 0.0


func on_interacted(player, hand_item):
	if cannot_enter:
		return

	if not player_inside:
		player_inside = player

		var player_root = player.get_player_root()
		player_root.set_player_driver(self)

	else:
		if is_instance_valid(player_inside):
			player_inside.get_player_root().exit_vehicle(
				get_exit_position()
			)
			player_exited()


func get_exit_position():
	return %ExitPosition.global_position


func player_exited():
	player_inside = null

	# Stop the car when driver leaves
	throttle_input = 0.0
	steering_input = 0.0

	cannot_enter = true
	await get_tree().create_timer(5.0).timeout
	cannot_enter = false


func throttle(throttle_amount):
	throttle_input = throttle_amount


func brake():
	throttle_input = -1.0


func release_throttle():
	throttle_input = 0.0


# Angle comes from joystick and is from -1.0 to 1.0
func steer(angle: float):
	steering_input = clamp(angle, -1.0, 1.0)
