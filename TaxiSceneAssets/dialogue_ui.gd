extends CanvasLayer

@onready var label = $Panel/RichTextLabel
@onready var fade_rect = $FadeRect

# Colleague is Faded CRT Yellow: #b8b072
# Her spoken words are Pale Muted Blue: #9cadb5
# Her internal thoughts are Dark Grey: #aaaaaa

var lines = [
	"[color=#9cadb5]Thank you for agreeing to drive me up here, by the way. I know it's completely out of the way.[/color]",
	"Colleague:[color=#b8b072] Of course. I had to inspect a site a few towns over anyway. Works out for both of us.[/color]",
	"Colleague:[color=#b8b072] Though I didn't expect the weather to get this bad. You sure this is the right turn? I can barely see past the hood.[/color]",
	"[color=#9cadb5]It's a few more miles. Just follow the treeline.[/color]",
	"Colleague:[color=#b8b072] It's going to be a long night. You should try to get some sleep. We won't hit the mountain pass until early morning.[/color]",
	"[color=#9cadb5]I'm fine. I just want to get there, sign the deed, and list it with the broker. We can head back by tomorrow afternoon.[/color]",
	"Colleague:[color=#b8b072] Must be a nice place, though. Your grandfather's cabin.[/color]",
	"[color=#9cadb5]It's just an old property. Wood and dust. Nothing special.[/color]",
	"Colleague:[color=#b8b072] Seems like a shame to just sell it off. Would be a good place to unplug.[/color]",
	"[color=#b8b072] I saw you staring at your phone earlier... waiting for a call?[/color]",
	"[color=#9cadb5]No. Just checking my inbox.[/color]",
	"[color=#aaaaaa][i](Twenty-four saved voicemails. I haven't deleted a single one.)[/i][/color]",
	"Colleague:[color=#b8b072] Hmm. Well, let me know if you need help with the paperwork. I know dealing with family estates can be heavy.[/color]",
	"[color=#9cadb5]It's fine. We hadn't spoken in years. I'm just here to finalize the paperwork.[/color]",
	"[color=#aaaaaa][i](A lie. I just want to smell the pinewood again. I want to sit on the porch where we used to play.)[/i][/color]",
	"Colleague:[color=#b8b072] ...[/color]",
	"Colleague:[color=#b8b072] Take your time. We've got all night.[/color]"
]

var current_line : int = 0
var is_typing : bool = false
var is_transitioning : bool = false

func _ready():
	# Start with the screen completely black
	fade_rect.modulate.a = 1.0
	
	# Fade in the scene over 2 seconds
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(fade_rect, "modulate:a", 0.0, 2.0)
	
	show_dialogue()

func show_dialogue():
	label.text = "[center]" + lines[current_line] + "[/center]"
	label.visible_characters = 0
	is_typing = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, 3.0)
	tween.finished.connect(_on_typing_finished)

func _on_typing_finished():
	is_typing = false

func _input(event):
	# Ignore clicks if we are already fading out to the next scene
	if is_transitioning:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if is_typing:
			label.visible_ratio = 1.0
			is_typing = false
		else:
			current_line += 1
			if current_line < lines.size():
				show_dialogue()
			else:
				start_scene_transition()

func start_scene_transition():
	is_transitioning = true
	label.hide() # Optional: Hide the text immediately when the fade out starts
	
	# Fade out to black over 2.5 seconds
	var fade_out = get_tree().create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 1.0, 2.5)
	fade_out.finished.connect(_load_next_scene)

func _load_next_scene():
	get_tree().change_scene_to_file("res://StoryTesting.tscn")
