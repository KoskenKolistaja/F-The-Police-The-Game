extends PathFollow3D

var reserved = false

@export var is_climbable = true

@export var path : Path3D


func _ready():
	if not path:
		path = get_parent()


func reset():
	reserved = false

func get_path_orientation_direct(curve: Curve3D) -> float:
	var count = curve.point_count
	if count < 2:
		return 0.0
	
	# Get positions directly from the curve
	var start = curve.get_point_position(0)
	var end = curve.get_point_position(count - 1)
	
	# Flatten the vector to ignore Y tilt
	var direction = end - start
	direction.y = 0.0
	
	# Use atan2(x, z) for Y-axis rotation
	return atan2(direction.x, direction.z)
