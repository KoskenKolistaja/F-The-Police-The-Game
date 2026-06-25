extends Node3D


var player_driving = false

@export var player_id = 0

@export var is_police : bool = false

@export var hud : Control

var private_visual_layer = null

var money : int = 1000




func _ready():
	
	if ItemData.police_id == player_id:
		is_police = true
		await get_tree().physics_frame
		ItemData.police_id = wrapi(ItemData.police_id + 1, 0, 2)
	
	private_visual_layer = player_id + 10
	
	
	if is_police:
		%PlayerCharacter.set_police()
		%FollowerCamera.set_police()
	
	hud.update_money(money)
	
	%PlayerCharacter.global_position = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	
	PlayerData.players[player_id] = self
	%PlayerCharacter.global_position = global_position
	
	print("Root print: " + str(is_police) + " Player id: " + str(player_id))
	
	%FollowerCamera.set_private_layer(private_visual_layer)


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
	
	if Input.is_action_just_pressed("p%s_open_info" % player_id):
		hud.open_police_info()
	
	if player_driving:
		hud.move_minimap_camera(%PlayerDriver.global_position)
	else:
		hud.move_minimap_camera(%PlayerCharacter.global_position)
	
	hud.rotate_minimap_camera(%FollowerCamera.rotation_degrees.y)
	var minimap_items = get_tree().get_first_node_in_group("minimap_items")
	minimap_items.set_icon_rotation(%FollowerCamera.rotation_degrees.y)

func set_player_driver(vehicle : Node3D,separate_camera_target = null):
	%PlayerCharacter.hide()
	%PlayerCharacter.active = false
	%PlayerDriver.vehicle = vehicle
	player_driving = true
	await get_tree().physics_frame
	%PlayerDriver.active = true
	await get_tree().physics_frame
	if separate_camera_target:
		%FollowerCamera.target = separate_camera_target
	else:
		%FollowerCamera.target = %PlayerDriver
	%FollowerCamera.driving = true

func exit_vehicle(exp_position):
	player_driving = false
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



func get_player_driver():
	return %PlayerDriver
