extends Node

@export var npc_container : Node3D
@export var npc_scene : PackedScene





func npc_died():
	var players = get_tree().get_nodes_in_group("player")
	var positions = get_tree().get_nodes_in_group("npc_spawn")
	positions.shuffle()

	for spawn_point in positions:
		var valid := true

		for player in players:
			if spawn_point.global_position.distance_to(player.global_position) < 10.0:
				valid = false
				break

		if valid:
			var npc_instance = npc_scene.instantiate()
			npc_container.add_child(npc_instance)
			npc_instance.global_position = spawn_point.global_position
			return

	# No valid spawn points found
	return
