extends Node3D

var player_character = null
var players_in_shot = []

## Capture all bodies inside the viewfinder area and start the memory timer
func use():
	var players = %Area3D.get_overlapping_bodies()
	players_in_shot = players
	%Timer.start()
	
	if players.is_empty():
		%Cursor.hide()
	
	for p in players:
		var cursor_position = get_viewport().get_camera_3d().unproject_position(p.global_position + (Vector3.UP*0.3))
		%Cursor.global_position = cursor_position
		%Cursor.show()
		if p.is_suspicious():
			%Cursor.modulate = Color(1,0,0)
		else:
			%Cursor.modulate = Color(0,1,0)

## Snap the photo: Criminalize suspicious players and cash in historical evidence banks
func use2():
	for p in players_in_shot:
		# Safety Check: Ensure the body is a valid player character and not an NPC
		if is_instance_valid(p) and "suspicion" in p:
			
			# ONLY process players who are currently inside their red-handed suspicion window
			if p.suspicion > 0.0 and not p.pending_crimes.is_empty():
				var caught_score = p.get_pending_crime_score()
				
				# Reset their local temporary suspicion window instantly
				p.suspicion = 0.0
				p.pending_crimes.clear()
				
				# CONVICT: Send the red-handed score to the Global Singleton.
				# This automatically triggers player.confirmed_criminal = true 
				# and unlocks all their archived 'banked' crimes!
				CrimeManager.criminalize(p, caught_score)
				print("Camera: Successfully snapped photo evidence of ", p.name)
				
		
		var hand_item_illegality = p.hand_item_illegality()
		
		if hand_item_illegality > 0:
			CrimeManager.criminalize(p,hand_item_illegality)
		
		
	# Clear the array immediately after processing the snap
	players_in_shot.clear()
	%Timer.stop()


func _on_timer_timeout():
	players_in_shot.clear()
	%Cursor.hide()

func set_visual_layer(layer : int,on : bool):
	%Camera.set_layer_mask_value(layer,on)
