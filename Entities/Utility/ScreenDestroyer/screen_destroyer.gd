extends VisibleOnScreenNotifier3D


@export var parent : Node3D


func activate():
	%Timer.start()

func _on_timer_timeout():
	if not is_on_screen():
		if parent:
			parent.queue_free()
		else:
			get_parent().queue_free()
	
	%Timer.wait_time = 5
