extends StaticBody3D

@export var icon : Texture
@export var price : int = 500
@export var item_name : String = "pistol"

@export var functional : bool = false

func _ready():
	if %IconScreen and icon:
		var mat : StandardMaterial3D = %IconScreen.get_active_material(0)
		mat.albedo_texture = icon
	
	%Interactable.message = "Buy: " + item_name


func on_interacted(player,hand_item):
	print("HERE")
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
	print("HERE?")
	var money = player.get_money()
	var player_root = player.get_player_root()
	
	print(money)
	print(money >= price)
	
	if money < price:
		return
	
	print("HERE TOO")
	
	if item_name == "clothes":
		player_root.set_money(-price)
		player.randomize_appearance()
	
	
