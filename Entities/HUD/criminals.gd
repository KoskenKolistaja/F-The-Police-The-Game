extends Panel

@export var player_panel : PackedScene




func update():
	for c in %PlayerPanelContainer.get_children():
		c.queue_free()
	
	for key in PoliceIntel.appearance_intel:
		var player = PlayerData.players[key]
		var appearance = PoliceIntel.appearance_intel[key]
		
		var tex = await PhotoBooth.get_photo(appearance)
		
		var panel_instance = player_panel.instantiate()
		
		var score = CrimeManager.get_total_crime_score(player)
		
		panel_instance.set_picture(tex)
		panel_instance.set_score(score)
		
		%PlayerPanelContainer.add_child(panel_instance)
		
