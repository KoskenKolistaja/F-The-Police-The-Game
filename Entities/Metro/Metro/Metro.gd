extends PathFollow3D

@export var is_engine : bool = false


@export var next_car : Node3D

var stopping = false
var looking_to_stop = true


var stops = [43,93,177,223]


var max_speed = 3.0
var speed = 3.0

var brake_strength = 0.022

func _physics_process(delta):
	if is_engine:
		progress += 0.1 * speed
	else:
		progress = next_car.progress - 2.5
	
	if looking_to_stop:
		for stop in stops:
			if abs(progress - stop) < 2.0:
				stopping = true
				looking_to_stop = false
				trigger_times()
	
	if stopping:
		speed = move_toward(speed,0,brake_strength)
	else:
		speed = move_toward(speed,max_speed,0.04)

func trigger_times():
	await get_tree().create_timer(7).timeout
	stopping = false
	await get_tree().create_timer(1).timeout
	looking_to_stop = true


func get_exit_position():
	var possible_positions = get_tree().get_nodes_in_group("exit_position")
	var closest_node = get_closest_position(possible_positions)
	
	
	if (closest_node.global_position - self.global_position).length() < 2.5:
		return closest_node.global_position
	else:
		return null

func get_closest_position(positions: Array) -> Node3D:
	var closest: Node3D = null
	var closest_distance := INF

	for pos in positions:
		if pos is Node3D:
			var distance = global_position.distance_squared_to(pos.global_position)

			if distance < closest_distance:
				closest_distance = distance
				closest = pos

	return closest


func on_interacted(player_character,hand_item):
	if hand_item:
		return
	var p_root = player_character.get_player_root()
	p_root.set_player_driver(self)
