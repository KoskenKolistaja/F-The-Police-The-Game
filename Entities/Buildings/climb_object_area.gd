extends Area3D


@export var parent : Node3D
@export var path_target : PathFollow3D
@export var path_target2 : PathFollow3D

func get_root():
	return parent

func get_path_target():
	var paths = [path_target,path_target2]
	
	print("GETTING?")
	print(path_target.reserved)
	
	for p in paths:
		if not p.reserved:
			print("GOT")
			return p
	
	return null

func setup_path_target(path, player_position):
	if path.is_climbable:
		var real_height = (player_position.y + 0.3) - parent.global_position.y
		path.progress = real_height
	else:
		var closest_progress = get_closest_path_progress_xz(path, player_position)
		path.progress = closest_progress
	
	path.reserved = true

func reset_path(path):
	path.reserved = false

func get_closest_path_progress_xz(path_node: PathFollow3D, player_pos: Vector3) -> float:
	var curve: Curve3D = path_node.get_parent().curve
	
	# Create a copy of the player position and flatten the Y axis
	# We set it to the path's starting Y level so the 3D calculation only looks at X and Z
	var flattened_player_pos = player_pos
	flattened_player_pos.y = path_node.get_parent().global_position.y
	
	# Convert global player position to the path's local coordinate space
	var local_pos = path_node.get_parent().to_local(flattened_player_pos)
	
	# get_closest_offset returns the exact progress (offset) along the curve
	return curve.get_closest_offset(local_pos)
