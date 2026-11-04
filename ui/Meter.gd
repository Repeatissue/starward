class_name Meter
extends Control
## One resource readout: icon, name, value, coloured bar and a plain-English hint below.

var kind := ""
var title := ""
var value := 0.0
var max_value := 100.0
var hint := ""
var low := false
var show_bar := true


func _init(p_kind: String = "", p_title: String = "", p_max: float = 100.0) -> void:
	kind = p_kind
	title = p_title
	max_value = p_max
	custom_minimum_size = Vector2(0, 44)
	mouse_filter = Control.MOUSE_FILTER_PASS


func set_data(p_value: float, p_hint: String, p_low: bool) -> void:
	value = p_value
	hint = p_hint
	low = p_low
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var col := UIKit.BAD if low else Icons.color_for(kind)
	if low:
		col = col.lerp(Color.WHITE, 0.25 * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)))
		queue_redraw()
	Icons.draw(self, kind, Rect2(2, 6, 28, 28), col)
	var x := 40.0
	var w := size.x - x
	draw_string(font, Vector2(x, 16), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UIKit.TEXT)
	draw_string(font, Vector2(x, 16), str(int(value)), HORIZONTAL_ALIGNMENT_RIGHT, w, 17, col)
	if show_bar:
		draw_rect(Rect2(x, 22, w, 7), Color(1, 1, 1, 0.08))
		draw_rect(Rect2(x, 22, w * clampf(value / maxf(max_value, 1.0), 0.0, 1.0), 7), col)
	draw_string(font, Vector2(x, 42), hint, HORIZONTAL_ALIGNMENT_LEFT, w, 13, UIKit.BAD if low else UIKit.DIM)
