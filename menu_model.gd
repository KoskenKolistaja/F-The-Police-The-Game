extends Node3D

@export var dead : bool = false
@export var pistol : bool = false




func _ready():
	if dead:
		%AnimationPlayer.play("die",-1,3.0,true)
	else:
		%AnimationPlayer.play("idle")
	
	if not pistol:
		%Pistol.hide()
	else:
		%GPUParticles3D.emitting = true

func _physics_process(delta):
	if pistol:
		%GPUParticles3D.global_position = %BarrelPosition2.global_position
