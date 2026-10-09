extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body.name != "Player":
		return

	print("Player entered the cabin!")

	var hint_ui = get_node_or_null("../LampHintUI")

	if hint_ui:
		hint_ui.show_hint()

	var lamp = get_tree().get_first_node_in_group("cabin_lamp")

	if lamp != null and not lamp.is_on:
		if lamp.lamp_highlight:
			lamp.lamp_highlight.show()
