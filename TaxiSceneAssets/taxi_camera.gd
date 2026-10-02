extends Camera3D

# --- Mouse Look Variables ---
var sensitivity : float = 0.003 
var yaw : float = 0.0
var pitch : float = 0.0
var start_yaw : float = 0.0
var start_pitch : float = 0.0

# --- Camera Bob Variables ---
var time_passed : float = 0.0
var bob_frequency : float = 15.0 # How fast the car rumbles
var bob_amplitude : float = 0.01 # How intense the rumble is
var start_y : float = 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Remember starting rotation for the mouse clamp
	yaw = rotation.y
	pitch = rotation.x
	start_yaw = rotation.y
	start_pitch = rotation.x
	
	# Remember starting height for the rumble effect
	start_y = position.y

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * sensitivity
		pitch -= event.relative.y * sensitivity
		
		# Lock horizontal to 90 degrees left and right
		yaw = clamp(yaw, start_yaw - deg_to_rad(90), start_yaw + deg_to_rad(90))
		# Lock vertical
		pitch = clamp(pitch, start_pitch - deg_to_rad(60), start_pitch + deg_to_rad(60))
		
		rotation.y = yaw
		rotation.x = pitch

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	time_passed += delta
	# Apply a subtle vertical vibration to simulate the engine and road
	position.y = start_y + sin(time_passed * bob_frequency) * bob_amplitude
