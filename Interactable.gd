extends Node
class_name Interactable

signal interacted

@export var message : String



func _ready():
	await get_tree().physics_frame
	interacted.connect(get_parent().on_interacted)

func get_pointing_position():
	if get_parent().has_method("get_pointing_position"):
		return get_parent().get_pointing_position()
	else:
		return null


func interact(player,hand_item = null):
	interacted.emit(player,hand_item)



func get_message(hand_item = null):
	return message
