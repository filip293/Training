extends CanvasLayer

@onready var label = $Panel/RichTextLabel
@onready var fade_rect = $FadeRect
@onready var vignette = $AmbientVignette
@onready var panel = $Panel

var lines = [
	"[color=#9cadb5]The air up here hasn't changed at all. Still smells like damp pine and woodsmoke.[/color]",
	"[color=#9cadb5]He always used to say the mountain has a longer memory than we do.[/color]",
	"[color=#aaaaaa][i](Twenty-four voicemails saved on my phone. The last one was left three days before he died.)[/i][/color]",
	"[color=#9cadb5]I told myself I was just coming to sign the papers. Just a transaction. Hand over the keys, take the check, and leave.[/color]",
	"[color=#aaaaaa][i](So why is my chest tight every time the wind moves through the branches?)[/i][/color]",
	"[color=#9cadb5]Just the paperwork. In and out.[/color]",
	"[color=#9cadb5]...God, I missed this porch.[/color]"
]

var current_line : int = 0
var is_typing : bool = false
var monologue_ended : bool = false

func _ready():
	# Fade in from black when the morning scene starts
	fade_rect.modulate.a = 1.0
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(fade_rect, "modulate:a", 0.0, 3.0)
	
	show_next_line()

func show_next_line():
	label.text = "[center]" + lines[current_line] + "[/center]"
	label.visible_characters = 0
	is_typing = true
	
	var type_tween = get_tree().create_tween()
	type_tween.tween_property(label, "visible_ratio", 1.0, 2.5)
	type_tween.finished.connect(_on_typing_finished)

func _on_typing_finished():
	is_typing = false
	
	# Wait 3 seconds on screen before moving forward
	await get_tree().create_timer(3.0).timeout
	
	# Check if this was the very last line
	if current_line >= lines.size() - 1:
		end_monologue()
	else:
		current_line += 1
		show_next_line()

func _input(event):
	if monologue_ended:
		return
		
	# Clicking instantly completes the current line, or skips to the next/end early
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if is_typing:
			label.visible_ratio = 1.0
			is_typing = false
		else:
			if current_line >= lines.size() - 1:
				end_monologue()
			else:
				current_line += 1
				show_next_line()

func end_monologue():
	monologue_ended = true
	
	# Smoothly fade out just the UI elements (Panel and Vignette) over 1.5 seconds
	var cleanup_tween = get_tree().create_tween()
	cleanup_tween.set_parallel(true)
	cleanup_tween.tween_property(panel, "modulate:a", 0.0, 1.5)
	cleanup_tween.tween_property(vignette, "modulate:a", 0.0, 1.5)
	cleanup_tween.finished.connect(_on_ui_fully_removed)

func _on_ui_fully_removed():
	# Completely free/delete the UI canvas layer so mouse cursor and inputs are fully free for gameplay
	queue_free()
