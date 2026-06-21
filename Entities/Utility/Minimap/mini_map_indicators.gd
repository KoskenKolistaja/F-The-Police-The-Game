extends Node3D






func set_icon_rotation(new_rotation):
	for c in get_children():
		c.rotation_degrees.y = new_rotation
