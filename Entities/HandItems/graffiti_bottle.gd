extends Node3D

var player_character

func use():
	%GPUParticles3D.emitting = true
	%Timer.start()

func _on_timer_timeout():
	%GPUParticles3D.emitting = false

func set_visual_layer(layer : int,on : bool):
	%GPUParticles3D.set_layer_mask_value(layer,on)
	%GraffitiBottle.set_layer_mask_value(layer,on)
