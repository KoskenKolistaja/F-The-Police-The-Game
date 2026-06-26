extends Node3D

@export var bomb_scene : PackedScene

@export var target_name : String = "Default Target"

var bomb = null
var bomber = null

@export var world_item : Node3D


signal finished(exploded : bool)

var bombing_success_templates = [
"Good job. See us and you'll get rewarded.",
"The job is done. We've got your payment ready.",
"Excellent work. You held up your end of the deal.",
"That's one less problem for us. Collect your reward.",
"You've earned yourself a nice payday.",
"The target is gone. We appreciate your professionalism.",
"You delivered exactly what was promised.",
"The explosion was heard loud and clear. Well done.",
"Business has improved thanks to your efforts.",
"You've done us a valuable service.",
"Consider your reputation with us improved."
]

var bombing_failure_templates = [
"We heard that you failed the task we provided. The Mafia won't forget.",
"The target is still standing. Unfortunate.",
"You had one job and somehow failed it.",
"The operation fell apart. We're not pleased.",
"You've cost us time and money.",
"The bomb never did its job. Neither did you.",
"We expected results. We got excuses.",
"The target survived and so did our problem.",
"Failure has consequences. Remember that.",
"We trusted you with a simple task. And somehow you f'd it up...",
"Don't expect us to overlook this mistake."
]

func on_interacted(player,hand_item):
	if hand_item == "time_bomb" and not bomb and player == bomber:
		player.remove_item_from_inventory("time_bomb")
		add_bomb()
	if hand_item == "defuse_kit" and bomb:
		bomb_defused()

func bomb_exploded():
	print("BOMB EXPLODED. BOMBER: " + str(bomber))
	finished.emit(true)
	
	if world_item:
		world_item.explode()
	
	if is_instance_valid(bomber):
		
		await get_tree().create_timer(3.0).timeout
		var dic = {
			"text": bombing_success_templates.pick_random(),
			"icon_name": "mafia_boss",
			"name": "Derek",
		}
		bomber.get_hud().add_character_message(dic)
		remove_from_group("bomb_target")
		%Timer.start()
		clear_target()

func bomb_defused():
	finished.emit(false)
	if is_instance_valid(bomber):
		var dic = {
			"text": bombing_failure_templates.pick_random(),
			"icon_name": "mafia_boss",
			"name": "Derek",
		}
		bomber.get_hud().add_character_message(dic)
		bomb.queue_free()
		%Timer.start()
		clear_target()
		remove_from_group("bomb_target")

func clear_target():
	bomber = null
	bomb = null
	%Mesh.set_layer_mask_value(10,false)
	%Mesh.set_layer_mask_value(11,false)
	%Mesh.set_layer_mask_value(12,false)
	%Mesh.set_layer_mask_value(13,false)

func add_bomb():
	var bomb_instance = bomb_scene.instantiate()
	add_child(bomb_instance)
	bomb_instance.global_transform = %BombPosition.global_transform
	bomb_instance.target = self
	bomb = bomb_instance

func get_target_name():
	return target_name


func mark_for_mafia(player):
	var layer_id = player.get_private_visual_layer()
	%Mesh.set_layer_mask_value(layer_id,true)

func mark_for_police(player = null):
	pass

func _on_timer_timeout():
	add_to_group("bomb_target")
