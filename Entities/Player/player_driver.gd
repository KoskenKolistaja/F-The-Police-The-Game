extends Node3D

@export var player_root : Node3D

var active = false
var possible_to_exit = true
var vehicle = null




func _physics_process(delta):
	if not active:
		return
	
	self.global_position = vehicle.global_position
	
	var player_id = player_root.player_id
	
	if Input.is_action_just_pressed("exit_vehicle"):
		if vehicle:
			var exit_position = vehicle.get_exit_position()
			if exit_position:
				player_root.exit_vehicle(exit_position)
				if vehicle.has_method("player_exited"):
					print("JUU")
					vehicle.player_exited()
					print(vehicle.cannot_enter)
	
	
	if vehicle.has_method("accelerate"):
		var input = Input.get_joy_axis(player_id,JOY_AXIS_TRIGGER_RIGHT)
		vehicle.accelerate(input)
	
	if vehicle.has_method("brake"):
		var input = Input.get_joy_axis(player_id,JOY_AXIS_TRIGGER_LEFT)
		if input > 0.5:
			vehicle.brake(input)
	
	if vehicle.has_method("steer"):
		var x = Input.get_joy_axis(player_id,JOY_AXIS_LEFT_X)
		if abs(x) > 0.2:
			vehicle.steer(x)
	
	
