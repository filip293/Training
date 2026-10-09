extends CanvasLayer

@onready var hint_label: Label = $HintLabel

var already_shown := false
var hint_tween: Tween


func show_hint() -> void:
	if already_shown:
		return

	already_shown = true

	hint_label.show()
	hint_label.modulate.a = 0.0

	hint_tween = create_tween()
	hint_tween.tween_property(hint_label, "modulate:a", 1.0, 0.5)
	hint_tween.tween_interval(4.0)
	hint_tween.tween_property(hint_label, "modulate:a", 0.0, 0.5)
	hint_tween.tween_callback(hint_label.hide)


func hide_hint() -> void:
	if hint_tween and hint_tween.is_running():
		hint_tween.kill()

	hint_label.hide()
	hint_label.modulate.a = 0.0
