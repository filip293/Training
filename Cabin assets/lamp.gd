extends Node3D

@export var lamp_light: Light3D
@export var lamp_highlight: MeshInstance3D

var is_on := false


func _ready() -> void:
	if lamp_light:
		lamp_light.visible = false

	if lamp_highlight:
		lamp_highlight.hide()


func try_interact_with(collider: Node) -> bool:
	if collider != self and not is_ancestor_of(collider):
		return false

	is_on = not is_on

	if lamp_light:
		lamp_light.visible = is_on

	if lamp_highlight:
		lamp_highlight.hide()

	if is_on:
		var hint_ui = get_tree().get_first_node_in_group("lamp_hint")
		if hint_ui:
			hint_ui.hide_hint()

	return true
