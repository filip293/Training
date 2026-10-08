extends CanvasLayer

@export var menu_camera : Camera3D
@export var player_camera : Camera3D
@export var narrative_ui : CanvasLayer 
@export var radio_player : Node # Links to your Background Music node

@onready var settings_panel = $SettingsPanel
@onready var menu_container = $MenuContainer
@onready var fade_rect = $FadeRect
@onready var title_label = $TitleLabel
@onready var start_button = $MenuContainer/StartButton

var master_bus : int
var is_game_started : bool = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	master_bus = AudioServer.get_bus_index("Master")
	fade_rect.modulate.a = 0.0 # Ensure screen is clear on boot
	
	# Force the menu music to be loud on boot
	if radio_player:
		radio_player.volume_db = 0.0

# --- Pause Logic ---
func _input(event):
	# Listen for Escape key, but only allow pausing if the story has begun
	if event.is_action_pressed("ui_cancel") and is_game_started:
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		# UNPAUSE
		get_tree().paused = false
		menu_container.visible = false
		title_label.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		# PAUSE
		get_tree().paused = true
		menu_container.visible = true
		title_label.visible = true
		settings_panel.visible = false
		start_button.text = "Continue"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# --- Menu Navigation ---
func _on_start_button_pressed():
	if not is_game_started:
		# 1. CINEMATIC START (First time only)
		is_game_started = true
		menu_container.visible = false 
		title_label.visible = false
		
		var tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(fade_rect, "modulate:a", 1.0, 2.0) # Fade to black
		
		# Fade the radio down to gameplay levels (-7 dB)
		if radio_player:
			tween.tween_property(radio_player, "volume_db", -7.0, 2.0)
			
		tween.chain().tween_callback(start_cinematic_gameplay)
	else:
		# 2. JUST UNPAUSING (Game already running)
		toggle_pause()

func start_cinematic_gameplay():
	# Swap cameras
	menu_camera.current = false
	player_camera.current = true
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if narrative_ui:
		narrative_ui.begin_story()
		
	# Fade back in from black over 2 seconds
	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 2.0)

func _on_settings_button_pressed():
	menu_container.visible = false
	settings_panel.visible = true

func _on_back_button_pressed():
	settings_panel.visible = false
	menu_container.visible = true

func _on_quit_button_pressed():
	get_tree().quit()

# --- Audio Control ---
func _on_master_slider_value_changed(value: float):
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
	AudioServer.set_bus_mute(master_bus, value < 0.05)
