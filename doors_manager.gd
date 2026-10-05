extends Node3D

@export var open_angle : float = 90.0      
@export var rotation_speed : float = 1.1   # Slightly increased duration to give the slow parts more breathing room
@export var door_sound : AudioStream       

var door_data = {}

func _ready() -> void:
	for child in get_children():
		if child is Node3D:
			_register_door(child)

func _register_door(door_node: Node3D) -> void:
	var closed_rot = door_node.global_rotation.y
	var open_rot = closed_rot + deg_to_rad(open_angle)
	
	door_data[door_node] = {
		"is_open": false,
		"is_moving": false,
		"closed_rot": closed_rot,
		"open_rot": open_rot
	}

func try_interact_with(collider: Node) -> void:
	var current = collider
	while current and current != self:
		if door_data.has(current):
			_animate_door(current)
			return
		current = current.get_parent()

func _animate_door(door_node: Node3D) -> void:
	var data = door_data[door_node]
	if data["is_moving"]:
		return
		
	data["is_moving"] = true
	var start_rot = door_node.global_rotation.y
	var target_rot = data["closed_rot"] if data["is_open"] else data["open_rot"]
	
	if door_sound:
		_play_spatial_sound(door_node.global_position)
	
	var tween = get_tree().create_tween()
	
	# TRANS_CUBIC with EASE_IN_OUT dramatically extends the slow start and slow end
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_method(
		func(p): door_node.global_rotation.y = lerp_angle(start_rot, target_rot, p),
		0.0,
		1.0,
		rotation_speed
	)
	
	tween.finished.connect(func():
		data["is_moving"] = false
		data["is_open"] = !data["is_open"]
	)

func _play_spatial_sound(pos: Vector3) -> void:
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = door_sound
	audio_player.global_position = pos
	audio_player.unit_size = 3.0
	audio_player.max_distance = 15.0
	get_tree().current_scene.add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(audio_player.queue_free)
