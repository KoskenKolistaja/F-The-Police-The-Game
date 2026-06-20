extends CharacterBody3D

const SPEED = 2.5
const WANDER_TIME_MIN = 1.0
const WANDER_TIME_MAX = 3.0

@onready var state_machine: AnimationNodeStateMachinePlayback = %AnimationTree.get("parameters/playback")
@onready var visual: Node3D = %Visual

@export var appearance_manager : Skeleton3D

var active: bool = true
var dead: bool = false
var sprinting: bool = false
var robbed_recently: bool = false
var money_sw: bool = false

var money: int = 100
var killer: Node3D = null
var robber: Node3D = null

var robbery_reported: bool = false
var murder_reported: bool = false

var on_metro_layer: bool = true
var on_upper_layer: bool = true

var robbery_countdown: float = 0.0
var rob_tick_timer: float = 0.0
var current_robber: Node3D = null

var investigation_countdown: float = 0.0
var current_investigator: Node3D = null
var investigated: float = 0.0
var investigation_need = 100.0

var wander_timer: float = 0.0 
var move_direction: Vector3 = Vector3.ZERO

var height_layer = 0

var is_ragdoll = false

func _ready() -> void:
	randomize()
	randomize_appearance()
	pick_new_wander_target()
	money *= randi_range(1, 5)
	investigation_need *= randf_range(2.0, 5.0)
	



func _physics_process(delta: float) -> void:
	
	if is_ragdoll:
		return
	
	if not active:
		return
	
	set_visual_layers(self.global_position.y)
	
	
	if robbery_countdown > 0 and not dead:
		robbery_countdown -= delta
		
		if robbery_countdown <= 0:
			if current_robber:
				start_fleeing_from_robbery(current_robber)
			return
		
		_freeze_and_apply_gravity(delta)
		state_machine.travel("interact-right")
		
		rob_tick_timer += delta
		if rob_tick_timer >= 0.66:
			rob_tick_timer = 0.0
			dispense_money_tick()
			
		return
	else:
		rob_tick_timer = 0.0
		
	if investigation_countdown > 0:
		investigation_countdown -= delta
		
		if not %RobberyTimer.is_paused():
			%RobberyTimer.set_paused(true)
		
		if not dead:
			if not %SpeechPlayer.is_playing():
				%SpeechPlayer.play("speech")
			%Speech.show()
		else:
			%Label3D.show()
		
		_freeze_and_apply_gravity(delta)
		state_machine.travel("idle")
		
		if is_instance_valid(current_investigator):
			var vector = current_investigator.global_position - global_position
			rotate_towards(vector)
			
		return
	else:
		if %RobberyTimer.is_paused():
			%RobberyTimer.set_paused(false)
		%InvestigationParticles.emitting = false
	
	if dead:
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	wander_timer -= delta
	if wander_timer <= 0:
		pick_new_wander_target()
	
	if move_direction != Vector3.ZERO:
		velocity.x = move_direction.x * SPEED
		velocity.z = move_direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if sprinting:
		velocity.x *= 1.75
		velocity.z *= 1.75
	
	if velocity.length() > 4.0:
		state_machine.travel("sprint")
	elif velocity.length() > 0.1:
		state_machine.travel("walk")
	else:
		state_machine.travel("idle")
		
	if move_direction.length() > 0:
		rotate_towards_delta(move_direction, delta)
	
	move_and_slide()

func randomize_appearance():
	appearance_manager.randomize_appearance()

func ragdoll(impact_velocity : Vector3 = Vector3.ZERO):
	is_ragdoll = true
	collision_off()
	%PhysicalBoneSimulator3D.physical_bones_start_simulation()
	%PhysicalBoneSimulator3D.influence = 1.0
	for bone : PhysicalBone3D in %PhysicalBoneSimulator3D.get_children():
		bone.apply_central_impulse(impact_velocity)
	await get_tree().create_timer(5).timeout
	deragdoll()

func deragdoll():
	global_position = %PhysicalBoneRoot.global_position
	state_machine.travel("idle")
	var tween = create_tween()

	tween.tween_property(
		%PhysicalBoneSimulator3D,
		"influence",
		0.0,
		0.5
	)

	await get_tree().create_timer(0.5).timeout
	is_ragdoll = false
	collision_on()
	%PhysicalBoneSimulator3D.physical_bones_stop_simulation()

func set_visual_layers(height):
	
	var visuals = []
	
	visuals.append_array(%Skeleton3D.get_children())
	visuals.append_array(%"character-male-a".get_children())
	visuals.append(%InvestigationParticles)
	visuals.append(%TearParticles)
	visuals.append(%TearParticles2)
	visuals.append(%Speech)
	visuals.append(%Label3D)
	
	if height > -0.1:
		var new_layer = 2
		if height_layer == new_layer:
			return
		height_layer = new_layer
		for v in visuals:
			if v.name == "RobbedIcon":
				continue
			if v is VisualInstance3D:
				v.set_layer_mask_value(2,true)
				v.set_layer_mask_value(3,false)
	elif height < -1.5:
		var new_layer = 1
		if height_layer == new_layer:
			return
		height_layer = new_layer
		for v in visuals:
			if v.name == "RobbedIcon":
				continue
			if v is VisualInstance3D:
				v.set_layer_mask_value(2,true)
				v.set_layer_mask_value(3,true)
	else:
		var new_layer = 0
		if height_layer == new_layer:
			return
		height_layer = new_layer
		for v in visuals:
			if v.name == "RobbedIcon":
				continue
			if v is VisualInstance3D:
				v.set_layer_mask_value(2,true)
				v.set_layer_mask_value(3,true)
	


func interact(player: Node3D, hand_item: String) -> void:
	match hand_item:
		"handcuffs":
			if "confirmed_criminal" in player and player.confirmed_criminal:
				get_arrested()
				player.remove_item_from_inventory("handcuffs")

func being_robbed(robber_node: Node3D) -> void:
	if not active:
		return
	
	
	
	
	%TearParticles.emitting = true
	%TearParticles2.emitting = true
	
	
	current_robber = robber_node
	robber = robber_node 
	if money <= 0 or robbed_recently:
		start_fleeing_from_robbery(robber_node)
		return
	state_machine.travel("interact-right")
	var vector = robber_node.global_position - self.global_position
	rotate_towards(vector)
	robbery_countdown = 0.2 
	move_direction = Vector3.ZERO 

	if robber_node.has_method("add_robbery_suspicion"):
		robber_node.add_robbery_suspicion()

func investigate(investigator: Node3D) -> void:
	if killer or robber:
		investigated += 1.0
		%RobbedIcon.hide()
	else:
		return
	
	if dead:
		%InvestigationParticles.emitting = true
	
	%RobberyTimer.wait_time += 0.1
	
	if active:
		current_investigator = investigator
		investigation_countdown = 0.2
		move_direction = Vector3.ZERO
	
	if investigated > investigation_need:
		if robber and not robbery_reported:
			CrimeManager.bank_crime(robber, CrimeManager.robbery_score)
			robbery_reported = true
			robber.add_robbery_suspicion()
		if killer and not murder_reported:
			CrimeManager.bank_crime(killer, CrimeManager.kill_score)
			murder_reported = true
		
		investigation_countdown = 0.0
		killer = null
		robber = null
		investigated = 0.0
		%RobbedIcon.hide()
		%Speech.hide()
		%SpeechPlayer.stop()
		%InvestigationParticles.emitting = false
		investigation_need *= randf_range(2.0, 5.0)

func dispense_money_tick() -> void:
	if money <= 0 or not active:
		return
		
	money -= 50
	if is_instance_valid(current_robber):
		if current_robber.has_method("collect_money"):
			current_robber.collect_money(50)
		elif "money" in current_robber:
			current_robber.money += 50
			
	if money <= 0:
		if current_robber:
			start_fleeing_from_robbery(current_robber)

func start_fleeing_from_robbery(robber_node) -> void:
	robbery_countdown = 0.0
	rob_tick_timer = 0.0
	robbed_recently = true
	money = 0 
	
	%RobbedIcon.show()
	%RobberyTimer.start()
	if is_instance_valid(robber_node):
		flee_away_from(robber_node)

func flee_away_from(robber_node: Node3D) -> void:
	if not active or not is_instance_valid(robber_node): 
		return
	
	var flee_dir = (global_position - robber_node.global_position).normalized()
	move_direction = Vector3(flee_dir.x, 0, flee_dir.z).normalized()
	wander_timer = 4.0 
	sprinting = true
	
	await get_tree().create_timer(4.0).timeout
	%TearParticles.emitting = false
	%TearParticles2.emitting = false
	sprinting = false

func _on_robbery_timer_timeout() -> void:
	robbed_recently = false
	%RobbedIcon.hide()
	money = 100 * randi_range(1, 5)

func _freeze_and_apply_gravity(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func pick_new_wander_target() -> void:
	var choice = randf()
	if choice < 0.4:
		move_direction = Vector3.ZERO
		wander_timer = randf_range(1.0, 3.0)
	else:
		var random_angle = randf_range(0, 2 * PI)
		move_direction = Vector3(sin(random_angle), 0, cos(random_angle)).normalized()
		wander_timer = randf_range(WANDER_TIME_MIN, WANDER_TIME_MAX)

func rotate_towards_delta(direction: Vector3, delta: float) -> void:
	var target_y = atan2(direction.x, direction.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, target_y, delta * 10.0)

func rotate_towards(direction: Vector3) -> void:
	var target_y = atan2(direction.x, direction.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, target_y, 0.1)



func get_message() -> String:
	return "Arrest"

func get_arrested() -> void:
	active = false
	state_machine.travel("holding-both")
	%ArrestHandcuffs.show()

func die(exp_killer = null) -> void:
	if exp_killer:
		killer = exp_killer
		if exp_killer.has_method("add_murder_suspicion"):
			exp_killer.add_murder_suspicion()
	dead = true
	deactivate()
	state_machine.travel("die")
	%TearParticles.emitting = false
	%TearParticles2.emitting = false
	%ArrestHandcuffs.hide()
	%RobbedIcon.hide()


func deactivate() -> void:
	active = false
	collision_off()

func activate() -> void:
	active = true
	collision_on()



func collision_off():
	set_collision_layer_value(1, false)
	print("COLLISION OFF CALLED")

func collision_on():
	set_collision_layer_value(1, true)
