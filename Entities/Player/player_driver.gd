extends Node3D

@export var player_root : Node3D

var active = false
var possible_to_exit = true
var vehicle = null




func _physics_process(delta):
	if not active:
		return
	
	self.global_position = vehicle.global_position
	
	
	if Input.is_action_just_pressed("exit_vehicle"):
		if vehicle:
			var exit_position = vehicle.get_exit_position()
			if exit_position:
				player_root.exit_vehicle(exit_position)
