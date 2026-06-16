extends Node

var debug_id = 0


var astar := AStar3D.new()

var lane_to_id : Dictionary = {}

var id_to_lane : Dictionary = {}


func _ready():
	await get_tree().create_timer(0.5).timeout
	build_graph()


func get_id():
	debug_id += 1
	return debug_id

func build_graph():
	astar.clear()
	lane_to_id.clear()
	id_to_lane.clear()
	var lanes = get_tree().get_nodes_in_group("lane")
	var id = 0
	for lane in lanes:
	
		lane_to_id[lane] = id
		id_to_lane[id] = lane
		
		astar.add_point(
			id,
			lane.global_position
		)
		
		id += 1
	
	for lane_a in lanes:
		for lane_b in lanes:
			if lane_a == lane_b:
				continue
			var out_pos = lane_a.out_socket.global_position
			var in_pos = lane_b.in_socket.global_position
			if out_pos.distance_to(in_pos) < 0.5:
				connect_lanes(lane_a, lane_b)

func connect_lanes(a : Lane, b : Lane):

	a.next_lanes.append(b)

	var id_a = lane_to_id[a]
	var id_b = lane_to_id[b]

	if not astar.are_points_connected(id_a, id_b):

		astar.connect_points(
			id_a,
			id_b,
			false
		)


func get_lane_path(
	start_lane : Lane,
	end_lane : Lane
) -> Array[Lane]:
	
	var start_id = lane_to_id[start_lane]

	var end_id = lane_to_id[end_lane]

	var point_path = astar.get_id_path(
			start_id,
			end_id
		)

	var lane_path : Array[Lane] = []

	for id in point_path:

		lane_path.append(
			id_to_lane[id]
		)

	return lane_path
