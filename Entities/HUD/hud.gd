extends Control


var info_open = false


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
