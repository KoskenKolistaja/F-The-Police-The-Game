extends Node3D

var player_character = null

@export var smoke_effect : PackedScene


func use():
	pass

func use2():
	var smoke_instance = smoke_effect.instantiate()
	var city = get_tree().get_first_node_in_group("city")
	city.add_child(smoke_instance)
	smoke_instance.global_position = self.global_position
	player_character.remove_item_from_inventory("smoke_bomb")

func set_visual_layer(layer : int,on : bool):
	%Mesh.set_layer_mask_value(layer,on)
