extends Control





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
