extends CharacterBody3D

@export_group("Cinematic Movement Settings")
@export var walk_speed: float = 2.0
@export var sprint_speed: float = 4.0
@export var developer_speed: float = 16.0
@export var acceleration: float = 8.0
@export var deceleration: float = 10.0
@export var air_control: float = 4.0
@export var jump_velocity: float = 4.0

@export_group("Look & Camera Settings")
@export var mouse_sensitivity: float = 0.002
@export var max_pitch: float = 85.0
@export var camera_tilt_amount: float = 0.035  # Subtle lean when strafing

@export_group("Head Bob Settings")
@export var bob_amplitude: float = 0.04       # Vertical bob height
@export var bob_h_amplitude: float = 0.02     # Horizontal swaying

@export_group("Footstep Settings")
## Meters between footsteps. The head bob uses this same distance.
@export var step_distance: float = 2.0
@export var default_footsteps: Array[AudioStream] = []
@export var grass_footsteps: Array[AudioStream] = []
@export var dirt_footsteps: Array[AudioStream] = []
@export var road_footsteps: Array[AudioStream] = []
@export var wood_footsteps: Array[AudioStream] = []
@export var stone_footsteps: Array[AudioStream] = []
@export var grass_texture_ids: Array[int] = []
@export var dirt_texture_ids: Array[int] = [0, 1, 2, 4]
@export var road_texture_ids: Array[int] = []
@export var stone_texture_ids: Array[int] = [3, 5]
## Prints the surface when it changes. Only works in the editor and debug exports.
@export var debug_surface: bool = false

@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var stamina_drain: float = 20.0
@export var stamina_regen: float = 12.0
@export var stamina_regen_delay: float = 1.5
@export var stamina_recover: float = 30.0

@export_group("Breathing")
## How long a fade between breathing recordings takes, in seconds.
@export var breath_fade_seconds: float = 0.75
@export_range(-40.0, 6.0, 0.5) var slight_breath_volume_db: float = 0.0
@export_range(-40.0, 6.0, 0.5) var heavy_breath_volume_db: float = 0.0
@export_range(-40.0, 6.0, 0.5) var exhausted_breath_volume_db: float = -10.0

@onready var camera: Camera3D = get_node_or_null("Camera3D")
@onready var interaction_ray: RayCast3D = get_node_or_null("Camera3D/RayCast3D")
@onready var interact_label: Label = get_node_or_null("HUD/InteractPrompt")
@onready var footstep_player: AudioStreamPlayer3D = get_node_or_null("FootstepAudioPlayer3D")
@onready var ground_ray: RayCast3D = get_node_or_null("GroundRay")
@onready var breath_slight: AudioStreamPlayer = get_node_or_null("BreathSlight")
@onready var breath_heavy: AudioStreamPlayer = get_node_or_null("BreathHeavy")
@onready var breath_exhausted: AudioStreamPlayer = get_node_or_null("BreathExhausted")

var rotation_x: float = 0.0
var bob_time: float = 0.0
var default_cam_pos: Vector3 = Vector3.ZERO
var target_tilt: float = 0.0

var stamina: float = 100.0
var sprint_locked: bool = false
var regen_wait: float = 0.0
var developer_movement: bool = false

var _breath_players: Array[AudioStreamPlayer] = []
var _breath_amount: Array[float] = [0.0, 0.0, 0.0]
var _last_surface_debug := ""

const _FOOTSTEP_PHASE := 3.0 * PI / 2.0
const _TERRAIN_BLEND := 0.5
const _MAX_GROUND_HITS := 4
const _SURFACE_NAMES: Array[String] = ["grass", "dirt", "road", "wood", "stone"]

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	stamina = max_stamina
	if camera:
		default_cam_pos = camera.position
	if interact_label:
		interact_label.hide()
	_breath_players = [breath_slight, breath_heavy, breath_exhausted]
	for player in _breath_players:
		_prepare_breath_player(player)
	if ground_ray:
		ground_ray.add_exception(self)

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

	# F8 exists in every build, but the fast movement is ignored outside debug exports and the editor.
	if OS.is_debug_build() and event.is_action_pressed("developer_speed"):
		developer_movement = not developer_movement
		print("Developer speed: ", "on" if developer_movement else "off")

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
	var sprinting := _is_sprinting(input_dir)
	var target_speed := _target_speed(sprinting)

	# Weighty movement interpolation
	var accel = acceleration if is_on_floor() else air_control
	var decel = deceleration if is_on_floor() else air_control

	if direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, direction.x * target_speed, accel * delta)
		velocity.z = lerp(velocity.z, direction.z * target_speed, accel * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, decel * delta)
		velocity.z = lerp(velocity.z, 0.0, decel * delta)

	_update_stamina(delta, sprinting)

	# Calculate camera tilt target based on horizontal input
	target_tilt = lerp(target_tilt, -input_dir.x * camera_tilt_amount, 5.0 * delta)

	move_and_slide()

	# Check what we are looking at to update the UI prompt
	_update_interaction_prompt()

	# Apply Camera effects and process footsteps
	_apply_cinematic_camera(delta)
	_update_breathing(delta)

func _is_sprinting(input_dir: Vector2) -> bool:
	if developer_movement or input_dir == Vector2.ZERO:
		return false
	if not Input.is_action_pressed("sprint"):
		return false
	if sprint_locked or stamina <= 0.0:
		return false
	return true

func _target_speed(sprinting: bool) -> float:
	if developer_movement:
		return developer_speed
	if sprinting:
		return sprint_speed
	return walk_speed

func _update_stamina(delta: float, sprinting: bool) -> void:
	if sprinting:
		stamina = maxf(stamina - stamina_drain * delta, 0.0)
		regen_wait = stamina_regen_delay
		if stamina <= 0.0:
			sprint_locked = true
		return

	if regen_wait > 0.0:
		regen_wait = maxf(regen_wait - delta, 0.0)
	elif stamina < max_stamina:
		stamina = minf(stamina + stamina_regen * delta, max_stamina)

	if sprint_locked and stamina >= stamina_recover:
		sprint_locked = false

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

	# One full camera dip per footstep. Horizontal sway stays at half that rate.
	var speed := Vector3(velocity.x, 0.0, velocity.z).length()
	if is_on_floor() and speed > 0.1 and step_distance > 0.0:
		var previous_bob := bob_time
		bob_time += delta * speed * (TAU / step_distance)
		var target_y := default_cam_pos.y + sin(bob_time) * bob_amplitude
		var target_x := default_cam_pos.x + cos(bob_time * 0.5) * bob_h_amplitude
		camera.position.y = lerp(camera.position.y, target_y, 10.0 * delta)
		camera.position.x = lerp(camera.position.x, target_x, 10.0 * delta)
		_play_footstep_if_due(previous_bob, bob_time)
	else:
		bob_time = 0.0
		camera.position = camera.position.lerp(default_cam_pos, 8.0 * delta)

func _play_footstep_if_due(before: float, after: float) -> void:
	var crossed := int(floor((after - _FOOTSTEP_PHASE) / TAU) - floor((before - _FOOTSTEP_PHASE) / TAU))
	for _i in mini(crossed, 3):
		_play_footstep_sound()

func _play_footstep_sound() -> void:
	if not footstep_player:
		return

	var detected := _detect_ground_surface()
	var surface := str(detected["surface"])
	var texture_id := int(detected["texture_id"])
	var audio_pool := _footsteps_for_surface(surface)
	if audio_pool.is_empty():
		audio_pool = default_footsteps
	_report_surface(surface, texture_id)

	if not audio_pool.is_empty():
		footstep_player.stream = audio_pool.pick_random()
		footstep_player.pitch_scale = randf_range(0.92, 1.05)
		footstep_player.play()

func _footsteps_for_surface(surface: String) -> Array[AudioStream]:
	match surface:
		"grass":
			return grass_footsteps
		"dirt":
			return dirt_footsteps
		"road":
			return road_footsteps
		"wood":
			return wood_footsteps
		"stone":
			return stone_footsteps
		_:
			return default_footsteps

func _detect_ground_surface() -> Dictionary:
	var found := {"surface": "", "texture_id": -1}
	if ground_ray == null or not is_inside_tree():
		return found
	var world := get_world_3d()
	if world == null:
		return found
	var space := world.direct_space_state
	if space == null:
		return found

	var origin := ground_ray.global_position
	var end := ground_ray.to_global(ground_ray.target_position)
	var exclude: Array[RID] = [get_rid()]
	for _attempt in _MAX_GROUND_HITS:
		var query := PhysicsRayQueryParameters3D.create(origin, end)
		query.collision_mask = ground_ray.collision_mask
		query.collide_with_bodies = ground_ray.collide_with_bodies
		query.collide_with_areas = ground_ray.collide_with_areas
		query.exclude = exclude
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return found
		var classified := _classify_collider(hit.get("collider"), hit.get("position", origin))
		if bool(classified.get("ground", false)):
			return classified
		var hit_rid: RID = hit.get("rid", RID())
		if not hit_rid.is_valid():
			return found
		exclude.append(hit_rid)
	return found

func _classify_collider(collider: Object, point: Vector3) -> Dictionary:
	var found := {"surface": "", "texture_id": -1, "ground": false}
	if collider == null:
		return found
	var node := collider as Node
	while node:
		var named := _surface_name_on(node)
		if named != "":
			return {"surface": named, "texture_id": -1, "ground": true}
		if node is Terrain3D:
			return _surface_from_terrain(node as Terrain3D, point)
		node = node.get_parent()
	var terrain := _find_scene_terrain()
	if terrain != null and _collider_is_terrain(terrain, collider):
		return _surface_from_terrain(terrain, point)
	return found

func _surface_name_on(node: Node) -> String:
	if node.has_meta("surface_type"):
		var named := str(node.get_meta("surface_type"))
		if _SURFACE_NAMES.has(named):
			return named
	for surface in _SURFACE_NAMES:
		if node.is_in_group(surface):
			return surface
	return ""

func _surface_from_terrain(terrain: Terrain3D, point: Vector3) -> Dictionary:
	var found := {"surface": "", "texture_id": -1, "ground": true}
	if terrain == null or not terrain.has_method("get_data"):
		return found
	var data: Object = terrain.get_data()
	if data == null or not data.has_method("get_texture_id"):
		return found
	var info: Variant = data.call("get_texture_id", point)
	if info is not Vector3:
		return found
	var ids := info as Vector3
	if is_nan(ids.x) or is_nan(ids.y) or is_nan(ids.z):
		return found
	var texture_id := int(ids.y) if ids.z >= _TERRAIN_BLEND else int(ids.x)
	if texture_id < 0:
		return found
	found["surface"] = _surface_for_texture(texture_id)
	found["texture_id"] = texture_id
	return found

func _surface_for_texture(texture_id: int) -> String:
	if grass_texture_ids.has(texture_id):
		return "grass"
	if dirt_texture_ids.has(texture_id):
		return "dirt"
	if road_texture_ids.has(texture_id):
		return "road"
	if stone_texture_ids.has(texture_id):
		return "stone"
	return ""

func _collider_is_terrain(terrain: Terrain3D, collider: Object) -> bool:
	if not terrain.has_method("get_collision") or collider is not CollisionObject3D:
		return false
	var collision: Object = terrain.get_collision()
	if collision == null or not collision.has_method("get_rid"):
		return false
	var terrain_rid: RID = collision.call("get_rid")
	return terrain_rid.is_valid() and collider.get_rid() == terrain_rid

func _find_scene_terrain() -> Terrain3D:
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get_node_or_null("Terrain3D") as Terrain3D

func _report_surface(surface: String, texture_id: int) -> void:
	if not debug_surface or not OS.is_debug_build():
		return
	var label := surface if surface != "" else "default"
	if texture_id >= 0:
		label += " texture %d" % texture_id
	if label == _last_surface_debug:
		return
	_last_surface_debug = label
	print("Footstep surface: ", label)

func _prepare_breath_player(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		push_warning("A breathing player is missing its audio stream.")
		return
	var looping := player.stream.duplicate() as AudioStreamMP3
	if looping == null:
		return
	looping.loop = true
	player.stream = looping
	player.bus = &"Master"
	player.volume_db = -80.0

func _update_breathing(delta: float) -> void:
	var band := _breath_band()
	var fade_step := delta / maxf(breath_fade_seconds, 0.05)
	for i in _breath_players.size():
		var target := 1.0 if i == band else 0.0
		_breath_amount[i] = move_toward(_breath_amount[i], target, fade_step)
		_apply_breath_level(i)

func _breath_band() -> int:
	if stamina > 70.0:
		return -1
	if stamina > 40.0:
		return 0
	if stamina > 15.0:
		return 1
	return 2

func _breath_volume_db(band: int) -> float:
	match band:
		0:
			return slight_breath_volume_db
		1:
			return heavy_breath_volume_db
		_:
			return exhausted_breath_volume_db

func _apply_breath_level(band: int) -> void:
	var player := _breath_players[band]
	if player == null or player.stream == null:
		return
	var amount := _breath_amount[band]
	if amount <= 0.001:
		if player.playing:
			player.stop()
		player.volume_db = -80.0
		return
	if not player.playing:
		player.play()
	var loudness := db_to_linear(_breath_volume_db(band)) * amount
	player.volume_db = linear_to_db(maxf(loudness, 0.0001))
