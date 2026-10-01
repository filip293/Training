@tool
extends Node3D

@export_category("Visibility Range Settings")
@export var apply_settings: bool = false:
	set(value):
		if value:
			apply_visibility_settings(self)
			print("Updated visibility range for all mesh instances!")
			apply_settings = false

@export var visibility_begin: float = 100.0
@export var visibility_begin_margin: float = 500.0
@export var visibility_end: float = 800.0
@export var visibility_end_margin: float = 900.0
@export var fade_mode: GeometryInstance3D.VisibilityRangeFadeMode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

func apply_visibility_settings(node: Node) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D:
			child.visibility_range_begin = visibility_begin
			child.visibility_range_begin_margin = visibility_begin_margin
			child.visibility_range_end = visibility_end
			child.visibility_range_end_margin = visibility_end_margin
			child.visibility_range_fade_mode = fade_mode
		
		# Recursively check sub-children (inside .glb instances)
		if child.get_child_count() > 0:
			apply_visibility_settings(child)
