class_name IconView
extends Control
## A square Control that draws one of the Icons kinds. Usable inside containers.

var kind: String = ""
var color: Color = Color.WHITE


func _init(p_kind: String = "", px: int = 32, p_color: Color = Color(0, 0, 0, 0)) -> void:
	kind = p_kind
	color = p_color if p_color.a > 0.0 else Icons.color_for(p_kind)
	custom_minimum_size = Vector2(px, px)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_icon(p_kind: String, p_color: Color = Color(0, 0, 0, 0)) -> void:
	kind = p_kind
	color = p_color if p_color.a > 0.0 else Icons.color_for(p_kind)
	queue_redraw()


func _draw() -> void:
	Icons.draw(self, kind, Rect2(Vector2.ZERO, size), color)
