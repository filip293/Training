extends CharacterBody3D

@export_group("Cinematic Movement Settings")
@export var walk_speed: float = 16.0
@export var acceleration: float = 8.0
@export var deceleration: float = 10.0
@export var air_control: float = 4.0
@export var jump_velocity: float = 4.0

@export_group("Look & Camera Settings")
@export var mouse_sensitivity: float = 0.002
@export var max_pitch: float = 85.0
@export var camera_tilt_amount: float = 0.035  # Subtle lean when strafing

@export_group("Head Bob Settings")
@export var bob_frequency: float = 2.4        # Speed of step cycle
@export var bob_amplitude: float = 0.04       # Vertical bob height
@export var bob_h_amplitude: float = 0.02     # Horizontal swaying

@export_group("Footstep Settings")
## Distance (in meters) the player must move to trigger a step
@export var step_distance: float = 2.2
@export var default_footsteps: Array[AudioStream] = []
@export var grass_footsteps: Array[AudioStream] = []
@export var road_footsteps: Array[AudioStream] = []
@export var house_footsteps: Array[AudioStream] = []

@onready var camera: Camera3D = get_node_or_null("Camera3D")
@onready var interaction_ray: RayCast3D = get_node_or_null("Camera3D/RayCast3D")
@onready var interact_label: Label = get_node_or_null("HUD/InteractPrompt")
@onready var footstep_player: AudioStreamPlayer3D = get_node_or_null("FootstepAudioPlayer3D")
@onready var ground_detector: Area3D = get_node_or_null("GroundDetectorArea3D")

var rotation_x: float = 0.0
var distance_traveled: float = 0.0
var bob_time: float = 0.0
var default_cam_pos: Vector3 = Vector3.ZERO
var target_tilt: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if camera:
		default_cam_pos = camera.position
	if interact_label:
		interact_label.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, deg_to_rad(-max_pitch), deg_to_rad(max_pitch))

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()

	# Interact key (using 'E' key)
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_try_interact()

	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Apply gravity smoothly
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump logic
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get WASD input direction
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_dir.y += 1.0
	input_dir = input_dir.normalized()

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Weighty movement interpolation
	var accel = acceleration if is_on_floor() else air_control
	var decel = deceleration if is_on_floor() else air_control

	if direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, direction.x * walk_speed, accel * delta)
		velocity.z = lerp(velocity.z, direction.z * walk_speed, accel * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, decel * delta)
		velocity.z = lerp(velocity.z, 0.0, decel * delta)

	# Calculate camera tilt target based on horizontal input
	target_tilt = lerp(target_tilt, -input_dir.x * camera_tilt_amount, 5.0 * delta)

	move_and_slide()

	# Check what we are looking at to update the UI prompt
	_update_interaction_prompt()

	# Apply Camera effects and process footsteps
	_apply_cinematic_camera(delta)
	_handle_footsteps(delta)

func _update_interaction_prompt() -> void:
	if not interaction_ray or not interact_label:
		return
		
	interaction_ray.force_raycast_update()
	
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider:
			# Traverse up parents to see if this object belongs to a doors manager
			var parent = collider.get_parent()
			while parent:
				if parent.has_method("try_interact_with"):
					interact_label.show()
					return
				parent = parent.get_parent()
			
	interact_label.hide()

func _try_interact() -> void:
	if not interaction_ray:
		return
		
	interaction_ray.force_raycast_update()
	
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider:
			# Find the parent manager and send the hit collider to it
			var parent = collider.get_parent()
			while parent:
				if parent.has_method("try_interact_with"):
					parent.try_interact_with(collider)
					return
				parent = parent.get_parent()

func _apply_cinematic_camera(delta: float) -> void:
	if not camera:
		return

	# Apply Pitch/Yaw rotation with target strafe tilt
	camera.rotation.x = rotation_x
	camera.rotation.z = lerp(camera.rotation.z, target_tilt, 10.0 * delta)

	# Procedural Head Bobbing
	var speed = Vector3(velocity.x, 0, velocity.z).length()
	if is_on_floor() and speed > 0.1:
		bob_time += delta * speed * bob_frequency
		var target_y = default_cam_pos.y + sin(bob_time) * bob_amplitude
		var target_x = default_cam_pos.x + cos(bob_time * 0.5) * bob_h_amplitude
		camera.position.y = lerp(camera.position.y, target_y, 10.0 * delta)
		camera.position.x = lerp(camera.position.x, target_x, 10.0 * delta)
	else:
		bob_time = 0.0
		camera.position = camera.position.lerp(default_cam_pos, 8.0 * delta)

func _handle_footsteps(delta: float) -> void:
	if not footstep_player:
		return
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	if is_on_floor() and horizontal_velocity.length() > 0.1:
		distance_traveled += horizontal_velocity.length() * delta
		if distance_traveled >= step_distance:
			distance_traveled = 0.0
			_play_footstep_sound()
	else:
		distance_traveled = step_distance * 0.5

func _play_footstep_sound() -> void:
	if not footstep_player:
		return

	var current_surface = _get_current_surface_from_area()
	var audio_pool: Array[AudioStream] = default_footsteps

	match current_surface:
		"grass":
			audio_pool = grass_footsteps
		"road":
			audio_pool = road_footsteps
		"house":
			audio_pool = house_footsteps
		_:
			audio_pool = default_footsteps

	if audio_pool.is_empty():
		audio_pool = default_footsteps

	if not audio_pool.is_empty():
		footstep_player.stream = audio_pool.pick_random()
		footstep_player.pitch_scale = randf_range(0.92, 1.05)
		footstep_player.play()

func _get_current_surface_from_area() -> String:
	if not ground_detector:
		return ""

	var overlapping_areas = ground_detector.get_overlapping_areas()
	for area in overlapping_areas:
		if area.is_in_group("grass"): return "grass"
		elif area.is_in_group("road"): return "road"
		elif area.is_in_group("house"): return "house"
		if area.has_meta("surface_type"):
			return area.get_meta("surface_type")

	var overlapping_bodies = ground_detector.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("grass"): return "grass"
		elif body.is_in_group("road"): return "road"
		elif body.is_in_group("house"): return "house"
		if body.has_meta("surface_type"):
			return body.get_meta("surface_type")

	return ""
