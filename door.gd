extends Node3D

@export var open_angle : float = 90.0      # How far the door swings open in degrees
@export var rotation_speed : float = 0.8   # Duration of the swing in seconds

var is_open : bool = false
var is_moving : bool = false

# This is the function your player script/raycast will call
func interact():
	if is_moving:
		return
		
	is_moving = true
	var target_angle = 0.0 if is_open else open_angle
	var target_rotation_y = deg_to_rad(target_angle)
	
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Smoothly rotates the hinge on the Y axis
	tween.tween_property(self, "rotation:y", target_rotation_y, rotation_speed)
	tween.finished.connect(_on_tween_finished)

func _on_tween_finished():
	is_moving = false
	is_open = !is_open
