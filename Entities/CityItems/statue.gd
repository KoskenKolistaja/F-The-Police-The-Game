extends Node3D


@export var fractured_statue : PackedScene






func explode():
	%Body.set_collision_layer_value(1,false)
	%StatueMesh.hide()
	for c in %FractureContainer.get_children():
		c.explode()
	
	%Timer.start()

func _on_timer_timeout():
	for c in %FractureContainer.get_children():
		c.queue_free()
	
	var s_instance = fractured_statue.instantiate()
	%FractureContainer.add_child(s_instance)
	
	%Body.set_collision_layer_value(1,true)
	%StatueMesh.show()
	
