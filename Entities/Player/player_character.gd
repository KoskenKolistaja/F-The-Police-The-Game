extends CharacterBody3D

const SPEED = 2.5
const JUMP_VELOCITY = 4.5
const DEADZONE = 0.2

const WANDER_TIME_MIN = 1.0
const WANDER_TIME_MAX = 3.0

@export var player_root : Node3D
@onready var state_machine : AnimationNodeStateMachinePlayback = %AnimationTree.get("parameters/playback")
@onready var visual = %Visual

var active = true
var city

var inventory_index = 0
var inventory = [
	"none",
	"graffiti_bottle",
	"pistol",
	"camera",
	"handcuffs",
	"spyglass"
]

var hand_item = "none"

# --- REFACTORED STATE ARCHITECTURE ---
var confirmed_criminal: bool = false
var suspicion: float = 0.0
var pending_crime_score: int = 0

# Joypad Button State Trackers
var prev_blend_pressed : bool = false
var prev_jump_pressed : bool = false
var prev_prev_pressed : bool = false
var prev_next_pressed : bool = false
var prev_check_climb_pressed : bool = false

@onready var civilian_bodies = [
	%body1, %body2, %body3, %body4, %body5,
	%body6, %body7, %body9, %businessbody, %workerbody
]

@onready var civilian_heads = [
	%head1, %head2, %head3, %head4, %head5,
	%head6, %head7, %head8, %head9, %head10, %workerhead,
]

# Social Stealth Variables
var is_blending_in: bool = false
var npc_wander_timer: float = 0.0
var npc_move_direction: Vector3 = Vector3.ZERO

var climb_object = null

func _ready():
	randomize()
	city = get_tree().get_first_node_in_group("city")
	%HandIK.start()
	set_inventory_item(0)

func _physics_process(delta):
	if not active:
		return
	
	# --- SUSPICION WINDOW EXPIRATION TICK ---
	if suspicion > 0.0:
		suspicion -= delta
		if suspicion <= 0.0:
			suspicion = 0.0
			pending_crime_score = 0 # Missed opportunity! Safe for now.
	
	player_root.hud.update_suspicion(suspicion)
	
	var player_id = player_root.player_id
	
	if not is_on_floor():
		if not climb_object:
			velocity += get_gravity() * delta

	var blend_pressed = Input.is_joy_button_pressed(player_id, JOY_BUTTON_Y)
	var jump_pressed = Input.is_joy_button_pressed(player_id, JOY_BUTTON_A)
	var sprint_pressed = false
	var use2_pressed = Input.is_joy_button_pressed(player_id, JOY_BUTTON_X)
	var check_climb_pressed = Input.is_joy_button_pressed(player_id, JOY_BUTTON_B)
	
	var next_pressed = Input.is_joy_button_pressed(player_id, JOY_BUTTON_RIGHT_SHOULDER)
	var previous_pressed = Input.is_joy_button_pressed(player_id, JOY_BUTTON_LEFT_SHOULDER)
	
	var next_just_pressed = next_pressed and not prev_next_pressed
	var previous_just_pressed = previous_pressed and not prev_prev_pressed
	
	if check_climb_pressed:
		check_climb_object()
	
	if next_just_pressed:
		set_inventory_item(+1)
	if previous_just_pressed:
		set_inventory_item(-1)
	
	if Input.get_joy_axis(player_id, JOY_AXIS_TRIGGER_LEFT) > 0.3:
		sprint_pressed = true

	var blend_just_pressed = blend_pressed and not prev_blend_pressed
	var jump_just_pressed = jump_pressed and not prev_jump_pressed
	
	if use2_pressed:
		for c in %HandItemSlot.get_children():
			if c.has_method("use2"):
				c.use2()
	
	prev_blend_pressed = blend_pressed
	prev_jump_pressed = jump_pressed
	prev_next_pressed = next_pressed
	prev_prev_pressed = previous_pressed

	if blend_just_pressed:
		is_blending_in = !is_blending_in
		if is_blending_in:
			pick_new_npc_target()

	if jump_just_pressed and is_on_floor() and not is_blending_in:
		velocity.y = JUMP_VELOCITY
		climb_object = null
	elif jump_just_pressed and climb_object:
		climb_object = null
		velocity.y = JUMP_VELOCITY
		is_blending_in = false
	
	var direction = Vector3.ZERO
	
	if climb_object:
		handle_climbing()
	elif is_blending_in:
		npc_wander_timer -= delta
		if npc_wander_timer <= 0:
			pick_new_npc_target()
		direction = npc_move_direction
	else:
		var input_dir = Vector2(
			Input.get_joy_axis(player_id, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
		)
		
		if input_dir.length() < DEADZONE:
			input_dir = Vector2.ZERO
			
		if input_dir != Vector2.ZERO:
			var camera = get_viewport().get_camera_3d()
			if camera:
				var cam_back = camera.global_transform.basis.z
				var cam_right = camera.global_transform.basis.x
				cam_back.y = 0
				cam_right.y = 0
				cam_back = cam_back.normalized()
				cam_right = cam_right.normalized()
				direction = (cam_right * input_dir.x + cam_back * input_dir.y).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if sprint_pressed and not is_blending_in:
		velocity.x *= 1.75
		velocity.z *= 1.75
	
	if not climb_object:
		if velocity.length() > 4:
			state_machine.travel("sprint")
		elif velocity.length() > 0.1:
			state_machine.travel("walk")
		else:
			state_machine.travel("idle")
		if direction.length() > 0:
			rotate_towards_delta(direction, delta)
	
	handle_interact_ray(player_id)
	move_and_slide()

func handle_climbing():
	var player_id = player_root.player_id
	var input_dir_y = Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
	
	if abs(input_dir_y) < 0.3:
		input_dir_y = 0
		state_machine.travel("idle")
	else:
		state_machine.travel("pick-up")
	
	if climb_object:
		climb_object.progress -= input_dir_y * 0.1
		var direction = climb_object.global_position - self.global_position
		rotate_towards(direction)
	
	velocity = climb_object.global_position - self.global_position
	move_and_slide()

func check_climb_object():
	var objects = %ClimbObjectArea.get_overlapping_areas()
	if not objects.is_empty():
		var object = objects[0]
		climb_object = object.get_path_target()
		object.setup_path_target(global_position.y + 0.3)

func rotate_towards_delta(exp_vector, delta):
	var target_y = atan2(exp_vector.x, exp_vector.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, target_y, delta * 10.0)

func rotate_towards(exp_vector):
	var target_y = atan2(exp_vector.x, exp_vector.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, target_y, 0.1)

func set_inventory_item(index_change):
	if inventory.is_empty():
		return
	inventory_index += index_change
	if inventory_index > inventory.size() - 1:
		inventory_index = 0
	if inventory_index < 0:
		inventory_index = inventory.size() - 1
	
	for c in %HandItemSlot.get_children():
		c.queue_free()
	
	if inventory_index == 0:
		player_root.hud.update_inventory_item("none")
		return
	
	var item_instance = ItemData.items[inventory[inventory_index]].instantiate()
	hand_item = inventory[inventory_index]
	player_root.hud.update_inventory_item(hand_item)
	%HandItemSlot.add_child(item_instance)
	item_instance.player_character = self

func handle_interact_ray(player_id):
	var rt_pressed = Input.get_joy_axis(player_id, JOY_AXIS_TRIGGER_RIGHT)
	rt_pressed = rt_pressed > 0.3
	
	var collider = %InteractRay.get_collider()

	if %InteractRay.is_colliding():
		%InfoLabel.text = collider.get_message()
		if Input.is_action_just_pressed("interact1"):
			collider.interact(self, null)
			
	if rt_pressed:
		if collider:
			collider.interact(self, hand_item)
		set_hand_item(1.0)
	else:
		set_hand_item(0.0)
	
	if not collider:
		%InfoLabel.text = ""

func set_hand_item(value):
	%HandIK.influence = move_toward(%HandIK.influence, value, 0.1)
	if value > 0.0:
		for c in %HandItemSlot.get_children():
			c.use()

func pick_new_npc_target() -> void:
	var choice = randf()
	if choice < 0.25:
		npc_move_direction = Vector3.ZERO
		npc_wander_timer = randf_range(1.0, 3.0)
	else:
		var random_angle = randf_range(0, 2 * PI)
		npc_move_direction = Vector3(sin(random_angle), 0, cos(random_angle)).normalized()
		npc_wander_timer = randf_range(WANDER_TIME_MIN, WANDER_TIME_MAX)

func get_player_root():
	return player_root

func set_police():
	for c in %Skeleton3D.get_children():
		c.hide()
	%policebody.show()
	%policehead.show()

func die(exp_killer = null):
	deactivate()
	state_machine.travel("die")
	%ArrestHandcuffs.hide()

func remove_item_from_inventory(item_name):
	inventory.erase(item_name)
	inventory_index = 0
	set_inventory_item(0)

func deactivate():
	active = false
	set_collision_layer_value(1, false)

func activate():
	active = true
	set_collision_layer_value(1, true)

func collect_money(amount):
	player_root.collect_money(amount)

func get_message():
	return "Arrest"

func get_arrested():
	active = false
	state_machine.travel("holding-both")
	%ArrestHandcuffs.show()

# --- GLOBAL PROFILE STATUS CHECK ---
func get_criminality() -> bool:
	return CrimeManager.is_wanted(self)

func is_suspicious() -> bool:
	if suspicion > 0.1:
		return true
	else:
		return false

## Received Call: Triggered if another player takes a photo of this character
func interact(player, incoming_hand_item):
	if incoming_hand_item == "handcuffs" and confirmed_criminal:
		get_arrested()
		player.remove_item_from_inventory("handcuffs")
		
	elif incoming_hand_item == "camera":
		# Caught red-handed! Upgrade suspicion window into a valid active conviction warrant
		if suspicion > 0.0 and pending_crime_score > 0:
			var caught_score = pending_crime_score
			suspicion = 0.0
			pending_crime_score = 0
			CrimeManager.criminalize(self, caught_score)

# --- INDIVIDUAL CRIME INFRACTION ENTRY POINTS ---
func add_graffiti_suspicion():
	suspicion = 20.0
	pending_crime_score += CrimeManager.graffiti_score

func add_murder_suspicion():
	suspicion = 20.0
	pending_crime_score += CrimeManager.kill_score

func add_gunfire_suspicion():
	suspicion = 20.0
	pending_crime_score += CrimeManager.graffiti_score

func add_robbery_suspicion():
	suspicion = 20.0
	pending_crime_score += CrimeManager.robbery_score
