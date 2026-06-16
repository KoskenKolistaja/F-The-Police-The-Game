extends Node3D

var player_character

func use():
	%GPUParticles3D.emitting = true
	%Timer.start()

func _on_timer_timeout():
	%GPUParticles3D.emitting = false
