extends CharacterBody3D

const SPEED = 2.5
const JUMP_VELOCITY = 4.5
const DEADZONE = 0.2

const WANDER_TIME_MIN = 1.0
const WANDER_TIME_MAX = 3.0

const SUSPICION_LENGTH = 60.0

@export var player_root : Node3D
@onready var state_machine : AnimationNodeStateMachinePlayback = %AnimationTree.get("parameters/playback")
@onready var visual = %Visual

var active = true
var city

var inventory_index = 0
var inventory = [
	"none"
]

var armor = false

var hand_item = "none"

var height_layer = -1

var player_id = null

var has_killed = false

# --- REFACTORED STATE ARCHITECTURE ---
var confirmed_criminal: bool = false
var suspicion: float = 0.0
var pending_crimes = []

# Joypad Button State Trackers
var prev_blend_pressed : bool = false
var prev_jump_pressed : bool = false
var prev_prev_pressed : bool = false
var prev_next_pressed : bool = false
var prev_check_climb_pressed : bool = false

@export var appearance_manager : Skeleton3D

# Social Stealth Variables
var is_blending_in: bool = false
var npc_wander_timer: float = 0.0
var npc_move_direction: Vector3 = Vector3.ZERO

var climb_object = null

var snapped_on_rope = false

func _ready():
	randomize()
	city = get_tree().get_first_node_in_group("city")
	%HandIK.start()
	set_inventory_item(0)
	
	await get_tree().create_timer(1.0).timeout
	
	print("Character print: " + str(is_police()))
	
	if player_root.is_police:
		set_police()
	else:
		set_civilian()
		GameManager.players_to_arrest.append(self)
	
	player_id = player_root.player_id
	
	PlayerData.players[player_id] = self
	
	if player_root.is_police:
		global_position = get_tree().get_first_node_in_group("police_station").global_position
	
	%InfoLabel.set_layer_mask_value(player_root.private_visual_layer,true)


func _physics_process(delta):
	if not active:
		return
	set_visual_layers(global_position.y)
	
	
	# --- SUSPICION WINDOW EXPIRATION TICK ---
	if suspicion > 0.0:
		suspicion -= delta
		if suspicion <= 0.0:
			suspicion = 0.0
			pending_crimes.clear()
	
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
		if climb_object:
			climb_object.reset()
			climb_object = null
	elif jump_just_pressed and climb_object:
		climb_object.reset()
		climb_object = null
		velocity.y = JUMP_VELOCITY
		is_blending_in = false
	
	var direction = Vector3.ZERO
	
	if climb_object:
		handle_climbing(delta)
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

func handle_climbing(delta: float):
	var player_id = player_root.player_id
	if not climb_object:
		return
	
	# =========================================================================
	# CASE 1: CLIMBING (Ladders / Vertical Structures)
	# =========================================================================
	if climb_object.is_climbable:
		var input_dir_y = Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
		
		if abs(input_dir_y) < 0.3:
			input_dir_y = 0
			state_machine.travel("idle")
		else:
			state_machine.travel("pick-up")
		
		climb_object.progress -= input_dir_y * SPEED * delta
		velocity = climb_object.global_position - self.global_position

	# =========================================================================
	# CASE 2: TIGHTROPE WALKING (Horizontal Paths with State-Based Y Alignment)
	# =========================================================================
	else:
		# 1. Match your normal walking camera-relative setup exactly
		var input_dir = Vector2(
			Input.get_joy_axis(player_id, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
		)
		
		if input_dir.length() < DEADZONE:
			input_dir = Vector2.ZERO
			
		var walk_direction = Vector3.ZERO
		if input_dir != Vector2.ZERO:
			var camera = get_viewport().get_camera_3d()
			if camera:
				var cam_back = camera.global_transform.basis.z
				var cam_right = camera.global_transform.basis.x
				cam_back.y = 0
				cam_right.y = 0
				walk_direction = (cam_right.normalized() * input_dir.x + cam_back.normalized() * input_dir.y).normalized()

		# 2. Sample the rope's local path vector at this exact point
		var current_pos = climb_object.global_position
		var orig_progress = climb_object.progress
		climb_object.progress += 0.1 # Peek down the track
		var forward_pos = climb_object.global_position
		climb_object.progress = orig_progress # Reset position state
		
		var rope_dir = (forward_pos - current_pos).normalized()
		rope_dir.y = 0 # Keep calculations flat on the walking plane

		# 3. Project your walking intent onto the tightrope line
		var move_factor = walk_direction.dot(rope_dir) if walk_direction != Vector3.ZERO else 0.0
		
		# 4. Only advance progress along the path if the player has actually snapped onto it
		if snapped_on_rope:
			climb_object.progress += move_factor * SPEED * delta

		# 5. Mirror normal ground locomotion transitions and turning feel
		if snapped_on_rope and abs(move_factor) > 0.05:
			state_machine.travel("walk")
			var look_direction = rope_dir if move_factor > 0.0 else -rope_dir
			rotate_towards_delta(look_direction, delta)
		elif snapped_on_rope:
			state_machine.travel("idle")
			rotate_towards_delta(rope_dir, delta)
			
		# =====================================================================
		# VELOCITY & SNAPPING ENGINE
		# =====================================================================
		# Forward Drive along the rope track line
		var forward_velocity = rope_dir * (move_factor * SPEED)
		
		# Find displacement distance to the tracking coordinate
		var offset_from_rope = climb_object.global_position - global_position
		
		# Horizontal Alignment (Kept relatively loose so movement feels natural)
		var HORIZONTAL_STRENGTH = 1.0
		var target_vel_x = forward_velocity.x + (offset_from_rope.x * HORIZONTAL_STRENGTH)
		var target_vel_z = forward_velocity.z + (offset_from_rope.z * HORIZONTAL_STRENGTH)
		
		# Vertical Alignment State Machine Switch
		var target_vel_y = velocity.y
		
		if not snapped_on_rope:
			# STATE A: Falling normally toward the wire
			var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
			target_vel_y -= gravity * delta * 0.5
			
			# Catchment Trigger: Check if player intersects or drops below the wire height
			if global_position.y <= climb_object.global_position.y or abs(offset_from_rope.y) < 0.15:
				snapped_on_rope = true
				# Hard position correction on impact frame to prevent clipping through the line
				global_position.y = climb_object.global_position.y
				target_vel_y = 0.0
		else:
			# STATE B: Safely landed. Apply strict vertical tracking.
			# A high multiplier keeps the player locked directly onto the line's Y path.
			var STRICT_Y_STRENGTH = 10.0
			target_vel_y = offset_from_rope.y * STRICT_Y_STRENGTH
		
		# Compile the tailored vector overrides cleanly
		velocity = Vector3(target_vel_x, target_vel_y, target_vel_z)

	# Execute final movement processing safely for whichever block ran
	move_and_slide()


func check_climb_object():
	var objects = %ClimbObjectArea.get_overlapping_areas()
	if climb_object:
		return
	
	if not objects.is_empty():
		var object = objects[0]
		climb_object = object.get_path_target()
		snapped_on_rope = false
		if climb_object:
			object.setup_path_target(climb_object,global_position)

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
	
	print(player_root)
	
	if inventory_index == 0:
		player_root.hud.update_inventory_item("none")
		hand_item = "none"
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
		if Input.is_action_just_pressed("p%s_interact1" % player_id):
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
			if hand_item == "graffiti_bottle":
				handle_graffiti_pointing()
			else:
				%GraffitiAnimation.play("RESET")


func handle_graffiti_pointing():
	var pointing_position = null
	var collider = %InteractRay.get_collider()
	
	if collider:
		if collider.has_method("get_pointing_position"):
			pointing_position = collider.get_pointing_position()
	
	
	print(pointing_position)
	
	if pointing_position:
		hand_target_point_towards(pointing_position)
	else:
		return

func hand_target_point_towards(pointing_position : Vector3):
	var target_node = %HandTarget
	
	# 1. Get the direction vector
	var direction = (pointing_position - target_node.global_position).normalized()
	
	# 2. Invert the direction (multiplying by -1) to account for the Z-axis offset
	var target_basis = Basis.looking_at(-direction, Vector3.UP)
	
	# 3. Create your custom offset rotation
	var offset_euler = Vector3(deg_to_rad(23.6), deg_to_rad(59.3), deg_to_rad(-6.2))
	var offset_basis = Basis.from_euler(offset_euler)
	
	# 4. Apply the orientation
	target_node.global_transform.basis = target_basis * offset_basis


func pick_new_npc_target() -> void:
	var choice = randf()

	if choice < 0.4:
		npc_move_direction = Vector3.ZERO
		npc_wander_timer = randf_range(1.0, 3.0)
		return

	var player_id = player_root.player_id
	var input_dir = Vector2(
		Input.get_joy_axis(player_id, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
	)

	if input_dir.length() > 0.5:
		var camera = get_viewport().get_camera_3d()

		if camera:
			var cam_back = camera.global_transform.basis.z
			var cam_right = camera.global_transform.basis.x

			cam_back.y = 0
			cam_right.y = 0

			cam_back = cam_back.normalized()
			cam_right = cam_right.normalized()

			npc_move_direction = (
				cam_right * input_dir.x +
				cam_back * input_dir.y
			).normalized()
	else:
		var random_angle = randf_range(0.0, TAU)
		npc_move_direction = Vector3(
			sin(random_angle),
			0,
			cos(random_angle)
		).normalized()

	npc_wander_timer = randf_range(WANDER_TIME_MIN, WANDER_TIME_MAX)

func get_player_root():
	return player_root




func set_police():
	for c in %Skeleton3D.get_children():
		if c is BoneAttachment3D:
			continue
		c.hide()
	add_to_group("police")
	
	appearance_manager.set_police()
	inventory.push_back("camera")
	inventory.push_back("pistol")
	inventory.push_back("spyglass")
	inventory.push_back("handcuffs")
	inventory.push_back("defuse_kit")


func set_civilian():
	appearance_manager.randomize_appearance()
	inventory.push_back("graffiti_bottle")
	inventory.push_back("smoke_bomb")
	inventory.push_back("pistol")

func die(exp_killer = null):
	if exp_killer:
		if exp_killer.has_method("add_murder_suspicion"):
			exp_killer.add_murder_suspicion()
	if not active:
		return
	
	if armor:
		armor = false
		player_root.hud.update_armor(armor)
		return
	
	Input.start_joy_vibration(player_id, 0.5, 1.0, 0.3)
	deactivate()
	state_machine.travel("die")
	%ArrestHandcuffs.hide()
	if player_root.is_police:
		await get_tree().create_timer(10).timeout
		activate()
		respawn("police_station")
	else:
		GameManager.arrest(self)
	


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
	player_root.set_money(amount)

func get_message():
	return "Arrest"

func get_arrested():
	active = false
	GameManager.arrest(self)
	state_machine.travel("holding-both")
	inventory_index = 0
	set_inventory_item(0)
	%ArrestHandcuffs.show()

# --- GLOBAL PROFILE STATUS CHECK ---
func get_criminality() -> bool:
	return CrimeManager.is_wanted(self)

func is_suspicious() -> bool:
	if suspicion > 0.1:
		return true
	elif hand_item_illegality() > 0:
		return true
	else:
		return false

## Received Call: Triggered if another player takes a photo of this character
func interact(player, incoming_hand_item):
	if incoming_hand_item == "handcuffs" and confirmed_criminal and active:
		get_arrested()
		player.remove_item_from_inventory("handcuffs")
		
	elif incoming_hand_item == "camera":
		var caught_score = get_pending_crime_score()
		# Caught red-handed! Upgrade suspicion window into a valid active conviction warrant
		if suspicion > 0.0 and caught_score > 0:
			suspicion = 0.0
			pending_crimes.clear()
			CrimeManager.criminalize(self, caught_score)

# --- INDIVIDUAL CRIME INFRACTION ENTRY POINTS ---
func add_graffiti_suspicion():
	if is_police():
		return
	suspicion = SUSPICION_LENGTH
	if not pending_crimes.has("graffiti"):
		pending_crimes.append("graffiti")

func add_murder_suspicion():
	if is_police():
		if inventory.has("pistol"):
			inventory.erase("pistol")
			inventory_index = 0
			set_inventory_item(0)
		var dic = {
		"text" : "Officer! You just shot a innocent civilian! That wont be tolerated. Your firearm has been suspended.",
		"icon_name" : "police_chief",
		"name" : "Chief Amanda",
		}
		
		get_hud().add_character_message(dic)
	suspicion = SUSPICION_LENGTH
	if not pending_crimes.has("murder"):
		pending_crimes.append("murder")
	has_killed = true

func add_gunfire_suspicion():
	if is_police():
		return
	suspicion = SUSPICION_LENGTH
	if not pending_crimes.has("gunfire"):
		pending_crimes.append("gunfire")

func add_robbery_suspicion():
	if is_police():
		return
	suspicion = SUSPICION_LENGTH
	if not pending_crimes.has("robbery"):
		pending_crimes.append("robbery")


func get_pending_crime_score() -> int:
	var value = 0
	for item in pending_crimes:
		if item == "murder":
			value += CrimeManager.kill_score
		elif item == "graffiti":
			value += CrimeManager.graffiti_score
		elif item == "robbery":
			value += CrimeManager.robbery_score
		elif item == "gunfire":
			value += CrimeManager.gunfire_score
	
	return value

func criminalize():
	confirmed_criminal = true
	player_root.hud.update_criminal_score(CrimeManager.get_total_crime_score(self))
	


func is_police():
	return player_root.is_police

func set_visual_layers(height):
	
	var visuals = []
	
	visuals.append_array(%Skeleton3D.get_children())
	visuals.append_array(%"character-male-a".get_children())
	
	var current_hand_item = null
	
	if not %HandItemSlot.get_children().is_empty():
		current_hand_item = %HandItemSlot.get_child(0)
	
	if height > -0.1:
		var new_layer = 2
		if height_layer == new_layer:
			return
		height_layer = new_layer
		
		if current_hand_item:
			current_hand_item.set_visual_layer(2,true)
			current_hand_item.set_visual_layer(3,false)
		for v in visuals:
			if v is VisualInstance3D:
				v.set_layer_mask_value(2,true)
				v.set_layer_mask_value(3,false)
	elif height < -1.5:
		var new_layer = 0
		if height_layer == new_layer:
			return
		height_layer = new_layer
		if current_hand_item:
			current_hand_item.set_visual_layer(2,true)
			current_hand_item.set_visual_layer(3,true)
		for v in visuals:
			if v is VisualInstance3D:
				v.set_layer_mask_value(2,true)
				v.set_layer_mask_value(3,true)
	else:
		var new_layer = 1
		if height_layer == new_layer:
			return
		height_layer = new_layer
		if current_hand_item:
			current_hand_item.set_visual_layer(2,true)
			current_hand_item.set_visual_layer(3,true)
		for v in visuals:
			if v is VisualInstance3D:
				v.set_layer_mask_value(2,true)
				v.set_layer_mask_value(3,true)

func get_camera_forward():
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return Vector3.FORWARD
	# Return the forward direction projected onto the horizontal plane
	return -camera.global_transform.basis.z * Vector3(1, 0, 1)

func is_stick_up_moving_forward(curve: Curve3D) -> bool:
	if curve.point_count < 2:
		return true # Default fallback
	
	# 1. Get the camera's flattened forward direction
	var cam_forward = get_camera_forward().normalized()
	
	# 2. Get the path's direction (from first to last point)
	var start = curve.get_point_position(0)
	var end = curve.get_point_position(curve.point_count - 1)
	
	# Flatten the path vector to match the horizontal plane
	var path_direction = (end - start)
	path_direction.y = 0.0
	path_direction = path_direction.normalized()
	
	# 3. Compare directions using the Dot Product
	var dot_result = cam_forward.dot(path_direction)
	
	# If dot_result > 0, camera and path align (Up = Forward)
	# If dot_result < 0, camera faces the start of the path (Up = Backward)
	return dot_result <= 0.0

func hand_item_illegality():
	
	if CrimeManager.get_total_crime_score(self) > 10:
		return 0
	
	if hand_item == "time_bomb":
		return 50
	if hand_item == "uzi":
		return 50
	if hand_item == "mp5":
		return 50
	if hand_item == "pistol":
		return 30
	elif hand_item == "graffiti_bottle":
		return 5
	else:
		return 0
	



func get_money():
	return player_root.money

func set_money(amount):
	player_root.set_money(amount)

func has_item(item_name):
	if inventory.has(item_name):
		return true
	else:
		return false


func inventory_last_item():
	inventory_index = inventory.size() - 1
	set_inventory_item(0)

func randomize_appearance():
	appearance_manager.randomize_appearance()
	var dic = {}
	dic["head"] = null
	dic["body"] = null
	dic["time"] = Time.get_ticks_msec()
	
	var whole_dic = {player_id : dic}
	
	PoliceIntel.add_appearance_intel(whole_dic)

func set_armor(on : bool):
	armor = on
	player_root.hud.update_armor(on)


func respawn(place_name : String):
	global_position = get_tree().get_first_node_in_group(place_name).global_position
	player_root.money = 100
	player_root.hud.update_money(player_root.money)

func get_hud():
	return player_root.hud

func get_private_visual_layer():
	return player_root.private_visual_layer

func get_appearance():
	return appearance_manager.get_appearance()


func get_appearance_intel():
	return {player_id : appearance_manager.get_appearance()}


func _on_city_part_checker_area_entered(area):
	player_root.hud.show_city_text(area.get_text())

func get_closest_city_part_name() -> String:
	var indicators = get_tree().get_nodes_in_group("city_part_indicator")

	var player_reference = self

	if not active:
		player_reference = player_root.get_player_driver()

	var closest = get_closest_from(indicators, player_reference)

	if closest == null:
		return ""

	return closest.get_text()


func get_closest_from(list, player_reference):
	if list.is_empty():
		return null

	var closest = null
	var closest_distance_sq = INF

	for item in list:
		var distance_sq = player_reference.global_position.distance_squared_to(
			item.global_position
		)

		if distance_sq < closest_distance_sq:
			closest_distance_sq = distance_sq
			closest = item

	return closest

func allowed_to_kill():
	if CrimeManager.get_total_crime_score(self) >= 150.0:
		return true
	else:
		return false
