extends Node3D


var painted = 0.0

var rewarded = false

var painter = null

var investigated = 0.0

func on_interacted(player,hand_item):
	if hand_item == "graffiti_bottle":
		paint(player)
	if hand_item == "spyglass":
		investigate()


func investigate():
	if painter:
		investigated += 1.0
	else:
		return
	
	if investigated > 100.0:
		CrimeManager.add_crime_score(painter,CrimeManager.graffiti_score)
		reset()

func paint(player):
	painted += 0.002
	
	
	if painted > 1.0 and not rewarded:
		paint_ready()
		rewarded = true
		painter = player
	elif not rewarded:
		var mat : StandardMaterial3D= %Graffiti.get_active_material(0)
		mat.albedo_color.a = painted

func paint_ready():
	pass


func reset():
	rewarded = false
	painter = null
	painted = 0.0
	var mat : StandardMaterial3D= %Graffiti.get_active_material(0)
	mat.albedo_color.a = painted
