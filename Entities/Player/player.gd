extends Node3D


var player_driving = false

@export var player_id = 0

@export var is_police : bool = false

@export var hud : Control


var money : int = 10000



func _ready():
	if is_police:
		%PlayerCharacter.set_police()
		%FollowerCamera.set_police()
	
	hud.update_money(money)
	
	%PlayerCharacter.global_position = Vector3(randf_range(-1,1),0,randf_range(-1,1))



func _physics_process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		if player_id == 0:
			player_id = 1
		else:
			player_id = 0
	
	if %PlayerCharacter.global_position.y < -1.5:
		%FollowerCamera.show_metro()
	else:
		%FollowerCamera.show_upper()


func set_player_driver(vehicle : Node3D):
	%FollowerCamera.target = %PlayerDriver
	%PlayerCharacter.hide()
	%PlayerCharacter.active = false
	%PlayerDriver.vehicle = vehicle
	await get_tree().physics_frame
	%PlayerDriver.active = true

func exit_vehicle(exp_position):
	%FollowerCamera.target = %PlayerCharacter
	%PlayerCharacter.show()
	%PlayerCharacter.active = true
	%PlayerDriver.active = false
	%PlayerCharacter.global_position = exp_position



func set_money(amount):
	money += amount
	hud.update_money(money)
