extends Node3D

var target = null

@export var explosion_scene : PackedScene

func _ready():
	%Timer.start()
	
	

func _physics_process(delta):
	%TimeLabel.text = "0 : " + str(snapped(%Timer.time_left,1))


func _on_timer_timeout():
	explode()




func explode():
	if target:
		target.bomb_exploded()
	%Mesh.hide()
	#%ExplosionEffects.emitting = true
	add_child(explosion_scene.instantiate())
	
	var bodies = %DeathArea.get_overlapping_bodies()
	
	for b in bodies:
		if b.has_method("die"):
			b.die()
	
	await get_tree().create_timer(2.5).timeout
	queue_free()

func defuse():
	target.bomb_defused()
	queue_free()
