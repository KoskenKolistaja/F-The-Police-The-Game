extends Node3D

@export var player_character : Node3D

var loaded = true

var max_trail_distance = 20.0
var trail_distance = 0.0

var tween : Tween

var spread = 0.5



func use():
	if player_character.is_police():
		return
	
	var npcs = %Area3D.get_overlapping_bodies()
	
	for npc in npcs:
		npc.being_robbed(player_character)


func use2():
	if loaded:
		shoot()
		player_character.add_gunfire_suspicion()


func shoot():
	# 1. Set the random spread FIRST so this shot actually uses it
	%RayCast3D.target_position = Vector3(randf_range(-spread, spread), randf_range(-spread, spread), -10)
	
	# 2. Force the raycast to update physics right now since we just changed its target
	%RayCast3D.force_raycast_update()
	
	# 3. Determine the global position the raycast is pointing at
	var global_target: Vector3
	if %RayCast3D.is_colliding():
		# If it hits something, point the trail exactly at the impact point
		global_target = %RayCast3D.get_collision_point()
		trail_distance = (global_target - %BarrelPosition.global_position).length()
	else:
		# If it misses, point it at the end of the max target range
		global_target = %RayCast3D.to_global(%RayCast3D.target_position)
		trail_distance = max_trail_distance

	# 4. Position and rotate the trail FIRST
	# (We do this before the tween because global_transform overwrites local scale)
	%MuzzleParticles.emitting = true
	%Trail.global_transform = %BarrelPosition.global_transform
	%Trail.look_at(global_target)
	%Trail.scale.z = 0.0 # Snap it to 0 immediately after positioning it
	
	# 5. GEMINI TWEEN TRAIL TO trail_distance HERE!
	if tween and tween.is_valid():
		tween.kill() # Kill the previous tween if the player is shooting rapidly
	
	tween = create_tween()
	
	# Tweens the Z-scale from 0 to our calculated distance over 0.05 seconds (very fast bullet feel)
	tween.tween_property(%Trail, "scale:z", trail_distance, 0.05)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)
		
	# OPTIONAL: Make the trail disappear after it finishes stretching
	# This shrinks it back down to 0 after a tiny delay so it doesn't float there forever
	#tween.tween_property(%Trail, "scale:z", 0.0, 0.1).set_delay(0.05)
	
	var collider = %RayCast3D.get_collider()
	
	if collider:
		if collider.has_method("die"):
			collider.die(player_character)
	
	# 6. Play animation and handle cooldown
	%AnimationPlayer.play("shoot")
	loaded = false
	await get_tree().create_timer(0.6).timeout
	loaded = true



func set_visual_layer(layer : int,on : bool):
	%Pistol.set_layer_mask_value(layer,on)
	%TrailMesh1.set_layer_mask_value(layer,on)
	%TrailMesh2.set_layer_mask_value(layer,on)
	%MuzzleParticles.set_layer_mask_value(layer,on)
