extends Node3D


var painted = 0.0

var rewarded = false

var painter = null

var investigated = 0.0


func _ready():
	# Make sure your material in the editor is a ShaderMaterial
	var mat : ShaderMaterial = %Graffiti.get_active_material(0)
	mat.set_shader_parameter("albedo_texture", ItemData.graffitis.pick_random())
	# Ensure it starts hidden
	mat.set_shader_parameter("reveal_progress", 0.0)

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
		CrimeManager.bank_crime(painter,CrimeManager.graffiti_score)
		player.set_money(100)
		reset()

func paint(player):
	painted += 0.002
	
	var mapped_progress = (clamp(painted, 0.0, 1.0) * 0.8) + 0.1
	
	
	painter = player
	player.add_graffiti_suspicion()
	
	# Get the shader material
	var mat : ShaderMaterial = %Graffiti.get_active_material(0)
	
	if painted >= 1.0 and not rewarded:
		paint_ready()
		rewarded = true
		player.set_money(100)
		%GPUParticles3D.emitting = true
		%Timer.start()
		%Background.hide()
		# Set to fully revealed
		mat.set_shader_parameter("reveal_progress", 1.0)
		
	elif not rewarded:
		# This is the "magic" line that drives the sweep animation
		mat.set_shader_parameter("reveal_progress", mapped_progress)
		%PointingPosition.progress_ratio = mapped_progress + 0.01

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


func get_pointing_position():
	return %PointingPosition.global_position
