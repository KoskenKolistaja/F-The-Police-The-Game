extends StaticBody3D

@export var icon : Texture
@export var price : int = 500
@export var item_name : String = "pistol"

@export var functional : bool = false

@export var only_police : bool = false
@export var only_civilian : bool = false

func _ready():
	if %IconScreen and icon:
		var mat : StandardMaterial3D = %IconScreen.get_active_material(0)
		mat.albedo_texture = icon
	
	%Interactable.message = "Buy " + item_name + " " + str(price) + "$"


func on_interacted(player,hand_item):
	if hand_item:
		return
	
	if only_police:
		if not player.is_police():
			return
	
	if only_civilian:
		if player.is_police():
			return
	
	if functional:
		function(player)
		return
	
	
	var money = player.get_money()
	var player_root = player.get_player_root()
	var has_item = player.has_item(item_name)
	
	if money < price:
		return
	
	
	
	if has_item:
		return
	
	player_root.set_money(-price)
	player.inventory.push_back(item_name)
	player.inventory_last_item()



func function(player):
	var money = player.get_money()
	var player_root = player.get_player_root()
	
	print(money)
	print(money >= price)
	
	if money < price:
		return
	
	
	if item_name == "clothes":
		player_root.set_money(-price)
		player.randomize_appearance()
	if item_name == "armor" and not player.armor:
		player_root.set_money(-price)
		player.set_armor(true)
	
