extends Node3D










func explode():
	var root = %StatueRoot

	for c: RigidBody3D in %FractureContainer.get_children():
		c.freeze = false
		c.show()

		# Direction away from root center
		var dir = (c.global_transform.origin - root.global_transform.origin).normalized()

		# Add upward bias + randomness
		dir += Vector3.UP * 0.4
		dir = dir.normalized()

		# Apply impulse away from root
		c.apply_central_impulse(dir * randf_range(3.0, 6.0))

		# Spin for visual chaos
		c.apply_torque_impulse(
			Vector3(
				randf_range(-0.02, 0.02),
				randf_range(-0.02, 0.02),
				randf_range(-0.02, 0.02)
			)
		)
