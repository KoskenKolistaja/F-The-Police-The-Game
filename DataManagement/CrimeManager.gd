extends Node

const CRIME_ACTIVE_DURATION = 20.0

var graffiti_score = 10
var gunfire_score = 10
var robbery_score = 30
var kill_score = 100

var active_warrants: Dictionary = {}
var evidence_bank: Dictionary = {}

func _process(delta: float) -> void:
	for player in active_warrants.keys():
		var crimes_list = active_warrants[player]
		
		for i in range(crimes_list.size() - 1, -1, -1):
			crimes_list[i].time_left -= delta
			if crimes_list[i].time_left <= 0.0:
				crimes_list.remove_at(i)
				
		if crimes_list.is_empty():
			active_warrants.erase(player)
			if is_instance_valid(player) and "confirmed_criminal" in player:
				player.confirmed_criminal = false

func bank_crime(player: Node3D, amount: int) -> void:
	if not is_instance_valid(player):
		return
		
	if is_confirmed_criminal(player):
		_register_warrant_item(player, amount)
		print("---- ACTIVE CRIMINAL UPDATED VIA INVESTIGATION: ", player.name, " | Added: ", amount, " | New Total: ", get_total_crime_score(player), " ----")
		return
		
	if not evidence_bank.has(player):
		evidence_bank[player] = 0
		
	evidence_bank[player] += amount
	print("---- EVIDENCE BANKED FOR ", player.name, " | Unverified Total: ", evidence_bank[player], " ----")

func criminalize(player: Node3D, caught_red_handed_amount: int) -> void:
	if not is_instance_valid(player):
		return
		
	if not active_warrants.has(player):
		active_warrants[player] = []
		
	_register_warrant_item(player, caught_red_handed_amount)
	
	if evidence_bank.has(player) and evidence_bank[player] > 0:
		var banked_total = evidence_bank[player]
		_register_warrant_item(player, banked_total)
		evidence_bank[player] = 0 
		print("---- EVIDENCE UNLOCKED! Historical score added: ", banked_total, " ----")
		
	if "confirmed_criminal" in player:
		player.confirmed_criminal = true
		
	print("---- PLAYER OFFICIALLY CRIMINALIZED: ", player.name, " | Live Score: ", get_total_crime_score(player), " ----")

func _register_warrant_item(player: Node3D, amount: int) -> void:
	active_warrants[player].append({
		"amount": amount,
		"time_left": CRIME_ACTIVE_DURATION
	})

func get_total_crime_score(player: Node3D) -> int:
	if not active_warrants.has(player):
		return 0
	var total = 0
	for warrant in active_warrants[player]:
		total += warrant.amount
	return total

func is_confirmed_criminal(player: Node3D) -> bool:
	return active_warrants.has(player) and not active_warrants[player].is_empty()
