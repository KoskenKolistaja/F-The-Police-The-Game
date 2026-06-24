extends StaticBody3D

@export var npc_name: String = "Derek"
@export var icon_name: String = "mafia_boss"

var intro_murder_templates = [
"There is a rat named %s running around. Deal with them.",
"My sources say %s is causing trouble. Get rid of them.",
"I need %s gone. Permanently.",
"Find %s and make sure they don't come back.",
"%s knows too much. I want you to silence them.",
"I've had enough of %s. Take care of the problem.",
"%s is interfering with business. Remove them.",
"The streets would be better off without %s. Eliminate them",
"I've got a contract with %s's name on it. Get them out of the way",
"%s has become a liability. Eliminate them.",
"Someone wants %s out of the picture and is paying good money for it.",
"Pay %s a visit. Make it their last.",
"%s thinks they're untouchable. Prove them wrong.",
"It's time for %s to disappear.",
"I don't want any problems from %s anymore. Take care of it",
"Your target is %s. Don't disappoint me.",
"I want %s gone by the end of the day.",
"%s has been asking for trouble. Deliver it.",
"One person stands between me and profit: %s. Make them go away",
]

var intro_bombing_templates = [
	"I want %s turned into a smoking crater. I've already provided the explosive.",
	"Plant an explosive at %s and leave no trace. The charge is yours.",
	"%s is becoming a problem. Blow it up. You'll find what you need on you already.",
	"Someone paid good money to see %s reduced to rubble. I've supplied the explosives.",
	"Go place a bomb at %s. Don't ask questions. The package is already in your hands.",
	"Your next target is to bomb %s. Make a big impression. I've equipped you for the task.",
	"I've got a demolition job for you: %s. Everything required has already been provided.",
	"%s has become a symbol of everything that's wrong. The charge is already yours. Make your point.",
	"The city needs a reminder. Place the explosive at %s and let everyone hear it.",
	"Some lessons need to be loud. You've already been issued an explosive. Deliver it at %s.",
	"We need to show them we don't play around anymore. %s is where the message gets sent. Plant an explosive there.",
	"The people responsible won't listen to words. Fortunately, you've already got something louder. Target: %s.",
	"The city has grown comfortable. It's time to remind them that comfort doesn't last. You need to blow up %s.",
	"You've already been supplied with the explosive. Use it at %s and give them something to think about.",
	"Nobody pays attention to warnings. Give them a message that is impossible to ignore. I want you to destroy %s with this compact, but powerful explosive device.",
	"This time it is not about profit. We're looking to be remembered. %s is your target.",
	"A charge has already been issued to you. Place it at %s and remind them who's still standing.",
	"This isn't about money anymore. It's about sending a message. Your target is %s. I want them to remember who is in charge.",
	"They need to understand that actions have consequences. Seeing %s reduced to rubble will help explain it.",
    "The explosive is already in your possession. Take it to %s and make sure the message lands."
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
	elif status == "failure":
		failure_sequence(player)
	else: # status == "active"
		notify_sequence(player)


func start_procedural_quest(player):
	var choice = randf()
	if choice > 0.01 and not get_tree().get_nodes_in_group("bomb_target").is_empty():
		start_procedural_bombing_quest(player)
	else:
		start_procedural_murded_quest(player)

func start_procedural_bombing_quest(player) -> void:
	var available_targets = get_tree().get_nodes_in_group("bomb_target")
	if available_targets.is_empty():
		return
	
	var target = available_targets.pick_random()
	
	# 1. Register the quest in the Autoload
	QuestManager.assign_procedural_bombing(player.player_id, target)
	
	# 2. Trigger your NPC's specific mafia logic!
	if target.has_method("mark_for_mafia"):
		target.mark_for_mafia(player)
		target.bomber = player
	
	# 3. Procedural text
	var target_name = target.get_target_name()
	var text = intro_bombing_templates.pick_random() % target_name
	
	player.inventory.push_back("time_bomb")
	player.inventory_last_item()
	
	send_hud_message(player, text)
	
	#await get_tree().create_timer(5.0).timeout
	#target.mark_for_police()
	#
	#var the_police = get_tree().get_nodes_in_group("police")
	#
	#var dic = {
		#"text" : "Listen up. It has come to our attention that the mafia is planning to eliminate %s. We can't let that happen. We have marked them for you." % target_npc.character_name,
		#"icon_name" : "police_chief",
		#"name" : "Chief Amanda",
	#}
	#
	#for p in the_police:
		#p.get_hud().add_character_message(dic)

func start_procedural_murded_quest(player) -> void:
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
	var text = intro_murder_templates.pick_random() % target_name
	
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


var notify_messages := [
	"What are you waiting for? You have a job to do!",
	"Quit standing around and get back to work!",
	"We have nothing to talk about.",
	"Don't just stand there. Get the job done!",
	"We're not paying you for that. Get moving!"
]

func notify_sequence(player) -> void:
	send_hud_message(player, notify_messages.pick_random())

func reward_sequence(player) -> void:
	send_hud_message(player, "A job well done. Nice to know the Mafia can count on you. Here is 2000$.")
	
	# Clear it immediately so the player can't spam the interact button
	QuestManager.complete_quest(player.player_id)
	
	await get_tree().create_timer(6.0).timeout
	player.set_money(2000)

func failure_sequence(player):
	send_hud_message(player, "It seems that you couldn't handle the task...")
	QuestManager.complete_quest(player.player_id)



func send_hud_message(player, message_text: String) -> void:
	var dic = {
		"text" : message_text,
		"icon_name" : icon_name,
		"name" : npc_name,
	}
	player.get_hud().add_character_message(dic)
