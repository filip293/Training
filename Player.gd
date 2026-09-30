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

@onready var camera: Camera3D = $Camera3D

var rotation_x: float = 0.0

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
