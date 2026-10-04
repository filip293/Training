extends Node3D

@export var open_angle : float = 90.0      # How far the door swings open in degrees
@export var rotation_speed : float = 0.8   # Duration of the swing in seconds

var is_open : bool = false
var is_moving : bool = false
var closed_rot_y : float = 0.0
var open_rot_y : float = 0.0

func _ready() -> void:
	# Save its starting global rotation and calculate the open target safely
	closed_rot_y = global_rotation.y
	open_rot_y = closed_rot_y + deg_to_rad(open_angle)

func interact():
	if is_moving:
		return
		
	is_moving = true
	
	# Decide whether we are heading back to closed or swinging open
	var start_rot = global_rotation.y
	var target_rot = closed_rot_y if is_open else open_rot_y
	
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Use tween_method with lerp_angle so it always takes the shortest path (no loops!)
	tween.tween_method(
		func(p): global_rotation.y = lerp_angle(start_rot, target_rot, p),
		0.0,
		1.0,
		rotation_speed
	)
	
	tween.finished.connect(_on_tween_finished)

func _on_tween_finished():
	is_moving = false
	is_open = !is_open
