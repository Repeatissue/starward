class_name CrewCard
extends Control
## Portrait, name, role and health/morale bars for one crew member.

var data: Dictionary = {}


func _init(p_data: Dictionary = {}) -> void:
	data = p_data
	custom_minimum_size = Vector2(0, 66)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if not data.is_empty():
		tooltip_text = "%s\n%s, %s\nHealth %d, Morale %d" % [data["name"], data["role"], data["trait"], int(data["health"]), int(data["morale"])]


func _draw() -> void:
	if data.is_empty():
		return
	var font := get_theme_default_font()
	var alive: bool = data["alive"]
	var role_col: Color = UIKit.ROLE_COLORS.get(data["role"], Color("b0bec5"))
	if not alive:
		role_col = Color(0.35, 0.37, 0.42)

	# Portrait
	var pc := Vector2(28, 32)
	draw_circle(pc, 26, role_col.darkened(0.72))
	draw_circle(pc + Vector2(0, -7), 9.5, role_col)
	draw_colored_polygon(Icons.arc_pts(pc + Vector2(0, 21), 14.0, PI, TAU, 14), role_col)
	draw_arc(pc, 26, 0, TAU, 36, role_col, 2.0, true)
	if not alive:
		draw_line(pc + Vector2(-14, -14), pc + Vector2(14, 14), UIKit.BAD, 2.5)
		draw_line(pc + Vector2(14, -14), pc + Vector2(-14, 14), UIKit.BAD, 2.5)

	var x := 64.0
	var w := size.x - x
	draw_string(font, Vector2(x, 18), str(data["name"]), HORIZONTAL_ALIGNMENT_LEFT, w, 16, UIKit.TEXT if alive else UIKit.DIM)
	var sub := "%s  ·  %s" % [data["role"], data["trait"]] if alive else "%s  ·  lost" % data["role"]
	draw_string(font, Vector2(x, 35), sub, HORIZONTAL_ALIGNMENT_LEFT, w, 13, role_col if alive else UIKit.DIM)
	if alive:
		var bw := (w - 8.0) * 0.5
		var hp := float(data["health"])
		var mood := float(data["morale"])
		var hp_col := UIKit.GOOD if hp >= 60.0 else (UIKit.ACCENT if hp >= 30.0 else UIKit.BAD)
		_bar(Vector2(x, 42), bw, hp / 100.0, hp_col)
		_bar(Vector2(x + bw + 8.0, 42), bw, mood / 100.0, UIKit.INFO)
		draw_string(font, Vector2(x, 62), "HEALTH %d" % int(hp), HORIZONTAL_ALIGNMENT_LEFT, bw, 11, UIKit.DIM)
		draw_string(font, Vector2(x + bw + 8.0, 62), "MORALE %d" % int(mood), HORIZONTAL_ALIGNMENT_LEFT, bw, 11, UIKit.DIM)


func _bar(pos: Vector2, w: float, frac: float, col: Color) -> void:
	draw_rect(Rect2(pos, Vector2(w, 6)), Color(1, 1, 1, 0.08))
	draw_rect(Rect2(pos, Vector2(w * clampf(frac, 0.0, 1.0), 6)), col)
