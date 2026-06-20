extends Node




var appearance_intel = {}

var example_dic = {0 : {
	"head" : "head1",
	"body" : "body2",
	"time" : 10000,
	}
}

func add_appearance_intel(new_intel: Dictionary) -> void:
	for player_id in new_intel:
		var incoming_data = new_intel[player_id]

		if not appearance_intel.has(player_id):
			appearance_intel[player_id] = incoming_data
			continue

		var current_data = appearance_intel[player_id]

		if incoming_data.get("time", 0) > current_data.get("time", 0):
			appearance_intel[player_id] = incoming_data
