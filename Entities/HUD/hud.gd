extends Control


var info_open = false

@export var minimap_camera_pivot : Node3D



func show_city_text(text):
	%CityNameLabel.add_new_item(text)


func move_minimap_camera(new_position):
	minimap_camera_pivot.global_position = new_position

func rotate_minimap_camera(new_angle):
	minimap_camera_pivot.rotation_degrees.y = new_angle

func update_money(amount):
	%MoneyLabel.text = str(amount) + "$"

func update_inventory_item(item_name : String):
	if item_name == "none":
		%InventoryItem.texture = null
		return
	
	%InventoryItem.texture = ItemData.icons[item_name]
	


func update_suspicion(value):
	%SuspicionBar.value = value

func update_criminal_score(value):
	print(value)
	if value > 0.0:
		value = clamp(value,13.0,1000.0)
	%CriminalScore.value = value

func update_armor(on : bool):
	if on:
		%ArmorIcon.show()
	else:
		%ArmorIcon.hide()


func open_police_info():
	if not info_open:
		%Criminals.update()
		%Criminals.show()
		info_open = true
	else:
		%Criminals.hide()
		info_open = false


func open_mafia_info():
	pass



func add_character_message(message_dic : Dictionary):
	%CharacterInfo.show_item(message_dic)
