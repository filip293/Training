extends Camera3D

var sensitivity : float = 0.003 
var yaw : float = 0.0
var pitch : float = 0.0
var start_yaw : float = 0.0
var start_pitch : float = 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	yaw = rotation.y
	pitch = rotation.x
	start_yaw = rotation.y
	start_pitch = rotation.x

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * sensitivity
		pitch -= event.relative.y * sensitivity
		
		# Lock horizontal to 90 degrees left and right
		yaw = clamp(yaw, start_yaw - deg_to_rad(90), start_yaw + deg_to_rad(90))
		# Lock vertical so the camera doesn't clip through the roof or floor
		pitch = clamp(pitch, start_pitch - deg_to_rad(60), start_pitch + deg_to_rad(60))
		
		rotation.y = yaw
		rotation.x = pitch

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
