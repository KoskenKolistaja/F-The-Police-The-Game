extends Node3D


var painted = 0.0

var rewarded = false

var painter = null

var investigated = 0.0


func _ready():
	var mat : StandardMaterial3D = %Graffiti.get_active_material(0)
	mat.albedo_texture = ItemData.graffitis.pick_random()

func on_interacted(player,hand_item):
	if hand_item == "graffiti_bottle":
		paint(player)
	if hand_item == "spyglass":
		investigate(player)


func investigate(player):
	if painter:
		investigated += 1.0
	else:
		return
	
	if investigated > 100.0:
		CrimeManager.bank_evidence(painter,CrimeManager.graffiti_score)
		player.set_money(100)
		reset()

func paint(player):
	painted += 0.002
	
	painter = player
	player.add_graffiti_suspicion()
	if painted > 1.0 and not rewarded:
		paint_ready()
		rewarded = true
		painter = player
		player.set_money(100)
		%GPUParticles3D.emitting = true
		%Timer.start()
		%Background.hide()
	elif not rewarded:
		var mat : StandardMaterial3D= %Graffiti.get_active_material(0)
		mat.albedo_color.a = painted

func paint_ready():
	pass


func reset():
	rewarded = false
	painter = null
	painted = 0.0
	investigated = 0.0
	var mat : StandardMaterial3D= %Graffiti.get_active_material(0)
	mat.albedo_color.a = painted
	%Background.show()


func _on_timer_timeout():
	reset()
