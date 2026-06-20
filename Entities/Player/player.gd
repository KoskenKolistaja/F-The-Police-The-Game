extends Node3D


var player_driving = false

@export var player_id = 0

@export var is_police : bool = false

@export var hud : Control


var money : int = 100



func _ready():
	if is_police:
		%PlayerCharacter.set_police()
		%FollowerCamera.set_police()
	
	hud.update_money(money)
	
	%PlayerCharacter.global_position = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	
	PlayerData.players[player_id] = self
	%PlayerCharacter.global_position = global_position

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
	
	if Input.is_action_just_pressed("open_info"):
		hud.open_police_info()

func set_player_driver(vehicle : Node3D,separate_camera_target = null):
	%PlayerCharacter.hide()
	%PlayerCharacter.active = false
	%PlayerDriver.vehicle = vehicle
	await get_tree().physics_frame
	%PlayerDriver.active = true
	await get_tree().physics_frame
	if separate_camera_target:
		%FollowerCamera.target = separate_camera_target
	else:
		%FollowerCamera.target = %PlayerDriver
	%FollowerCamera.driving = true

func exit_vehicle(exp_position):
	%PlayerCharacter.show()
	%PlayerCharacter.active = true
	%PlayerDriver.active = false
	%PlayerCharacter.global_position = exp_position
	await get_tree().physics_frame
	%FollowerCamera.target = %PlayerCharacter
	%FollowerCamera.driving = false


func set_money(amount):
	money += amount
	hud.update_money(money)
