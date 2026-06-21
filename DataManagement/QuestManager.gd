extends Node

# Dictionary structure: { player_id: { "target_node": Node, "status": String } }
var active_tasks: Dictionary = {}

func get_quest_status(player_id) -> String:
	if not active_tasks.has(player_id): 
		return ""
		
	var task = active_tasks[player_id]
	
	# 1. If they already succeeded, return success immediately.
	# We do this FIRST because dead NPCs are removed from memory.
	if task.get("status") == "success":
		return "success"
		
	# 2. If it's active, check if the NPC randomly despawned/vanished
	var target = task.get("target_node")
	if not is_instance_valid(target):
		active_tasks.erase(player_id) # Clean up the broken quest
		return ""
		
	return task.get("status", "")

func assign_procedural_murder(player_id, target_npc: Node) -> void:
	active_tasks[player_id] = {
		"target_node": target_npc,
		"status": "active"
	}
	
	# CONNECT_ONE_SHOT ensures the signal disconnects automatically when it fires
	if target_npc.has_signal("died"):
		target_npc.died.connect(func(): _on_target_died(player_id), CONNECT_ONE_SHOT)

func _on_target_died(player_id) -> void:
	if active_tasks.has(player_id):
		active_tasks[player_id]["status"] = "success"
		# Safely clear the pointer so we don't hold a reference to a deleted object
		active_tasks[player_id]["target_node"] = null

func complete_quest(player_id) -> void:
	active_tasks.erase(player_id)
