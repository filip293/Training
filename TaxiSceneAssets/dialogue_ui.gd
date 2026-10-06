extends CanvasLayer

@onready var label = $Panel/RichTextLabel
@onready var fade_rect = $FadeRect
@onready var voice_player = $VoicePlayer

var lines = [
	"[color=#9cadb5]Thank you for agreeing to drive me up here, by the way. I know it's completely out of the way.[/color]",
	"Colleague:[color=#b8b072] Of course. I had to inspect a site a few towns over anyway. Works out for both of us.[/color]",
	"Colleague:[color=#b8b072] Though I didn't expect the weather to get this bad. You sure this is the right turn? I can barely see past the hood.[/color]",
	"[color=#9cadb5]It's a few more miles. Just follow the treeline.[/color]",
	"Colleague:[color=#b8b072] It's going to be a long night. You should try to get some sleep. We won't hit the mountain pass until early morning.[/color]",
	"[color=#9cadb5]I'm fine. I just want to get there, sign the deed, and list it with the broker. We can head back by tomorrow afternoon.[/color]",
	"Colleague:[color=#b8b072] Must be a nice place, though. Your grandfather's cabin.[/color]",
	"[color=#9cadb5]It's just an old property. Wood and dust. Nothing special.[/color]",
	"Colleague:[color=#b8b072] Seems like a shame to just sell it off. Would be a good place to unplug. I saw you staring at your phone earlier... waiting for a call?[/color]",
	"[color=#9cadb5]No. Just checking my inbox.[/color]",
	"[color=#aaaaaa][i](Twenty-four saved voicemails. I haven't deleted a single one.)[/i][/color]",
	"Colleague:[color=#b8b072] Hmm. Well, let me know if you need help with the paperwork. I know dealing with family estates can be heavy.[/color]",
	"[color=#9cadb5]It's fine. We hadn't spoken in years. I'm just here to finalize the paperwork.[/color]",
	"[color=#aaaaaa][i](A lie. I just want to smell the pinewood again. I want to sit on the porch where we used to play.)[/i][/color]",
	"Colleague:[color=#b8b072] ...[/color]",
	"Colleague:[color=#b8b072] Take your time. We've got all night.[/color]"
]

# Tweak these numbers to match the pacing of your ElevenLabs audio file.
# Each number is the time (in seconds) that line stays on screen before advancing.
# Adjusted for slower, emotional AI speech pacing
var line_durations = [
	5.5,  # Line 0: "Thank you for agreeing..."
	6.3,  # Line 1: "Of course. I had to inspect..."
	7.5,  # Line 2: "Though I didn't expect..."
	4.0,  # Line 3: "It's a few more miles..."
	6.5,  # Line 4: "It's going to be a long night..."
	6.5,  # Line 5: "I'm fine. I just want..."
	3.5,  # Line 6: "Must be a nice place..."
	5.5,  # Line 7: "It's just an old property..."
	8.5,  # Line 8: "Seems like a shame..."
	3.5,  # Line 9: "No. Just checking my inbox."
	5.5,  # Line 10: "(Twenty-four saved voicemails...)"
	6.0,  # Line 11: "Hmm. Well, let me know..."
	5.0,  # Line 12: "It's fine. We hadn't spoken..."
	7.5,  # Line 13: "(A lie. I just want to smell...)"
	0.0,  # Line 14: "..."
	4.5   # Line 15: "Take your time..."
]

var current_line : int = 0
var is_transitioning : bool = false

func _ready():
	fade_rect.modulate.a = 1.0
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(fade_rect, "modulate:a", 0.0, 2.0)
	
	# Start the single audio file once
	voice_player.play() 
	show_dialogue()

func show_dialogue():
	label.text = "[center]" + lines[current_line] + "[/center]"
	label.visible_characters = 0
	
	# Get the duration for this specific line (fallback to 3.0s if missing)
	var current_duration = 3.0
	if current_line < line_durations.size():
		current_duration = line_durations[current_line]
	
	# Make the text finish typing slightly before the audio line ends (80% of the total duration)
	var type_tween = get_tree().create_tween()
	type_tween.tween_property(label, "visible_ratio", 1.0, current_duration * 0.80)
	
	# Start a timer for the full duration of the line + pause
	var timer = get_tree().create_timer(current_duration)
	timer.timeout.connect(_on_line_timer_finished)

func _on_line_timer_finished():
	current_line += 1
	if current_line < lines.size():
		show_dialogue()
	else:
		# Wait for 5 seconds before starting the scene transition
		await get_tree().create_timer(5.0).timeout
		start_scene_transition()

func start_scene_transition():
	is_transitioning = true
	label.hide() 
	
	var fade_out = get_tree().create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 1.0, 2.5)
	fade_out.finished.connect(_load_next_scene)

func _load_next_scene():
	get_tree().change_scene_to_file("res://StoryTesting.tscn")
