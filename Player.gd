extends CharacterBody3D

@export_group("Movement Settings")
@export var max_speed: float = 2.0
@export var acceleration: float = 30.0
@export var deceleration: float = 40.0
@export var air_control: float = 12.0
@export var jump_velocity: float = 5.0

@export_group("Look Settings")
@export var mouse_sensitivity: float = 0.003
@export var max_pitch: float = 89.0

@export_group("Footstep Settings")
## Distance (in meters) the player must move to trigger a footstep
@export var step_distance: float = 1.8
@export var default_footsteps: Array[AudioStream] = []
@export var grass_footsteps: Array[AudioStream] = []
@export var road_footsteps: Array[AudioStream] = []
@export var house_footsteps: Array[AudioStream] = []

@onready var camera: Camera3D = $Camera3D
@onready var footstep_player: AudioStreamPlayer3D = $FootstepAudioPlayer3D
@onready var ground_detector: Area3D = $GroundDetectorArea3D

var rotation_x: float = 0.0
var distance_traveled: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, deg_to_rad(-max_pitch), deg_to_rad(max_pitch))
		if camera:
			camera.rotation.x = rotation_x

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()

	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0
	input_dir = input_dir.normalized()

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var accel = acceleration if is_on_floor() else air_control
	var decel = deceleration if is_on_floor() else air_control

	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * max_speed, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * max_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
		velocity.z = move_toward(velocity.z, 0.0, decel * delta)

	move_and_slide()

	_handle_footsteps(delta)

func _handle_footsteps(_delta: float) -> void:
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	if is_on_floor() and horizontal_velocity.length() > 0.1:
		distance_traveled += horizontal_velocity.length() * _delta
		if distance_traveled >= step_distance:
			distance_traveled = 0.0
			_play_footstep_sound()
	else:
		distance_traveled = 0.0

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

	# Fallback if specific array is empty
	if audio_pool.is_empty():
		audio_pool = default_footsteps

	if not audio_pool.is_empty():
		footstep_player.stream = audio_pool.pick_random()
		footstep_player.pitch_scale = randf_range(0.9, 1.1)
		footstep_player.play()

func _get_current_surface_from_area() -> String:
	if not ground_detector:
		return ""

	# Check overlapping areas detected by feet
	var overlapping_areas = ground_detector.get_overlapping_areas()
	for area in overlapping_areas:
		# Check groups on the area
		if area.is_in_group("grass"):
			return "grass"
		elif area.is_in_group("road"):
			return "road"
		elif area.is_in_group("house"):
			return "house"
		
		# Check metadata on the area
		if area.has_meta("surface_type"):
			return area.get_meta("surface_type")

	# Check overlapping bodies (if roads/houses are StaticBody3D)
	var overlapping_bodies = ground_detector.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("grass"):
			return "grass"
		elif body.is_in_group("road"):
			return "road"
		elif body.is_in_group("house"):
			return "house"

		if body.has_meta("surface_type"):
			return body.get_meta("surface_type")

	return ""
