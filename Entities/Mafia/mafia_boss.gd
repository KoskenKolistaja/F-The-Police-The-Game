extends StaticBody3D

@export var npc_name: String = "Derek"
@export var icon_name: String = "mafia_boss"

var intro_templates = [
	"There is a rat named %s running around. Deal with them.",
	"My sources say %s is causing trouble. Get rid of them.",
	"Go and kill %s before I kill you!"
]

func on_interacted(player, hand_item) -> void:
	if hand_item:
		return
		
	var p_id = player.player_id
	var status = QuestManager.get_quest_status(p_id)
	
	if status == "":
		start_procedural_quest(player)
	elif status == "success":
		reward_sequence(player)
	else: # status == "active"
		notify_sequence(player)

func start_procedural_quest(player) -> void:
	var available_npcs = get_tree().get_nodes_in_group("npc")
	if available_npcs.is_empty():
		return
		
	var target_npc = available_npcs.pick_random()
	
	# 1. Register the quest in the Autoload
	QuestManager.assign_procedural_murder(player.player_id, target_npc)
	
	# 2. Trigger your NPC's specific mafia logic!
	if target_npc.has_method("mark_for_mafia"):
		target_npc.mark_for_mafia(player)
	
	# 3. Procedural text
	var target_name = target_npc.get("character_name") if "character_name" in target_npc else "Someone"
	var text = intro_templates.pick_random() % target_name
	
	send_hud_message(player, text)
	
	await get_tree().create_timer(5.0).timeout
	target_npc.mark_for_police()
	
	var the_police = get_tree().get_nodes_in_group("police")
	
	var dic = {
		"text" : "Listen up. It has come to our attention that the mafia is planning to eliminate %s. We can't let that happen. We have marked them for you." % target_npc.character_name,
		"icon_name" : "police_chief",
		"name" : "Chief Amanda",
	}
	
	for p in the_police:
		p.get_hud().add_character_message(dic)


func notify_sequence(player) -> void:
	send_hud_message(player, "What are you waiting for? You have a job to do!")

func reward_sequence(player) -> void:
	send_hud_message(player, "A job well done. Nice to know the Mafia can count on you. Here is 2000$.")
	
	# Clear it immediately so the player can't spam the interact button
	QuestManager.complete_quest(player.player_id)
	
	await get_tree().create_timer(6.0).timeout
	player.set_money(2000)

func send_hud_message(player, message_text: String) -> void:
	var dic = {
		"text" : message_text,
		"icon_name" : icon_name,
		"name" : npc_name,
	}
	player.get_hud().add_character_message(dic)
