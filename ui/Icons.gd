class_name Icons
extends RefCounted
## Vector icons drawn in code, so the prototype needs no image files.
## Call Icons.draw() from inside a Control's _draw().


static func color_for(kind: String) -> Color:
	return UIKit.KIND_COLORS.get(kind, UIKit.TEXT)


static func arc_pts(center: Vector2, r: float, a0: float, a1: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		out.append(center + Vector2(cos(a), sin(a)) * r)
	return out


static func _poly(c: Vector2, s: float, pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(c + p * s)
	return out


static func draw(ci: CanvasItem, kind: String, rect: Rect2, color: Color) -> void:
	var c := rect.get_center()
	var s := minf(rect.size.x, rect.size.y) * 0.5
	var dark := color.darkened(0.65)
	var w := maxf(1.5, s * 0.14)
	match kind:
		"fuel":
			var pts := PackedVector2Array([c + Vector2(0, -0.95) * s])
			pts.append_array(arc_pts(c + Vector2(0, 0.2) * s, 0.62 * s, -PI / 6.0, PI + PI / 6.0, 14))
			ci.draw_colored_polygon(pts, color)
			ci.draw_circle(c + Vector2(-0.22, 0.25) * s, 0.13 * s, color.lightened(0.5))
		"food":
			ci.draw_circle(c + Vector2(-0.22, 0.2) * s, 0.5 * s, color)
			ci.draw_circle(c + Vector2(0.22, 0.2) * s, 0.5 * s, color)
			ci.draw_line(c + Vector2(0, -0.25) * s, c + Vector2(0.1, -0.75) * s, color.darkened(0.35), w)
			ci.draw_colored_polygon(_poly(c, s, [Vector2(0.1, -0.6), Vector2(0.65, -0.9), Vector2(0.4, -0.45)]), color.lightened(0.25))
		"oxygen":
			ci.draw_arc(c + Vector2(-0.2, 0.2) * s, 0.55 * s, 0, TAU, 24, color, w, true)
			ci.draw_arc(c + Vector2(0.5, -0.45) * s, 0.3 * s, 0, TAU, 16, color, w, true)
			ci.draw_circle(c + Vector2(-0.38, 0.02) * s, 0.12 * s, color)
		"power":
			ci.draw_colored_polygon(_poly(c, s, [Vector2(0.2, -1), Vector2(-0.55, 0.15), Vector2(-0.05, 0.15),
				Vector2(-0.2, 1), Vector2(0.55, -0.15), Vector2(0.05, -0.15)]), color)
		"hull":
			ci.draw_colored_polygon(_poly(c, s, [Vector2(-0.75, -0.75), Vector2(0.75, -0.75), Vector2(0.7, 0.15),
				Vector2(0, 0.95), Vector2(-0.7, 0.15)]), color)
			ci.draw_line(c + Vector2(0, -0.6) * s, c + Vector2(0, 0.7) * s, dark, w)
		"parts":
			for i in 8:
				var a := TAU * i / 8.0
				var dir := Vector2(cos(a), sin(a))
				var perp := Vector2(-dir.y, dir.x)
				ci.draw_colored_polygon(PackedVector2Array([c + (dir * 0.5 - perp * 0.17) * s, c + (dir * 0.95 - perp * 0.12) * s,
					c + (dir * 0.95 + perp * 0.12) * s, c + (dir * 0.5 + perp * 0.17) * s]), color)
			ci.draw_circle(c, 0.62 * s, color)
			ci.draw_circle(c, 0.24 * s, dark)
		"credits":
			ci.draw_circle(c, 0.85 * s, color)
			ci.draw_arc(c, 0.62 * s, 0, TAU, 24, dark, w, true)
			ci.draw_line(c + Vector2(0, -0.4) * s, c + Vector2(0, 0.4) * s, dark, w * 1.3)
		"colonists":
			ci.draw_rect(Rect2(c + Vector2(-0.4, -0.5) * s, Vector2(0.8, 1.0) * s), color)
			ci.draw_circle(c + Vector2(0, -0.5) * s, 0.4 * s, color)
			ci.draw_circle(c + Vector2(0, 0.5) * s, 0.4 * s, color)
			ci.draw_rect(Rect2(c + Vector2(-0.2, -0.45) * s, Vector2(0.4, 0.75) * s), Color(0.75, 0.95, 1.0))
		"crew":
			ci.draw_circle(c + Vector2(0, -0.38) * s, 0.34 * s, color)
			ci.draw_colored_polygon(arc_pts(c + Vector2(0, 0.95) * s, 0.78 * s, PI, TAU, 16), color)
		"time":
			ci.draw_arc(c, 0.8 * s, 0, TAU, 28, color, w, true)
			ci.draw_line(c, c + Vector2(0, -0.55) * s, color, w)
			ci.draw_line(c, c + Vector2(0.4, 0.15) * s, color, w)
		"station":
			# Hub with a docking ring and two solar wings.
			ci.draw_rect(Rect2(c + Vector2(-1.0, -0.22) * s, Vector2(0.42, 0.44) * s), color)
			ci.draw_rect(Rect2(c + Vector2(0.58, -0.22) * s, Vector2(0.42, 0.44) * s), color)
			ci.draw_line(c + Vector2(-0.6, 0) * s, c + Vector2(0.6, 0) * s, color, w)
			ci.draw_arc(c, 0.48 * s, 0, TAU, 24, color, 0.16 * s, true)
			ci.draw_circle(c, 0.2 * s, color)
		"hazard":
			ci.draw_colored_polygon(_poly(c, s, [Vector2(0, -0.92), Vector2(0.95, 0.8), Vector2(-0.95, 0.8)]), color)
			ci.draw_line(c + Vector2(0, -0.32) * s, c + Vector2(0, 0.28) * s, dark, w * 1.2)
			ci.draw_circle(c + Vector2(0, 0.55) * s, 0.1 * s, dark)
		"derelict":
			ci.draw_colored_polygon(_poly(c, s, [Vector2(-0.95, -0.15), Vector2(-0.15, -0.5), Vector2(-0.02, 0.0), Vector2(-0.8, 0.35)]), color)
			ci.draw_colored_polygon(_poly(c, s, [Vector2(0.12, -0.05), Vector2(0.92, 0.12), Vector2(0.82, 0.55), Vector2(0.04, 0.35)]), color.darkened(0.2))
			ci.draw_circle(c + Vector2(0.05, -0.55) * s, 0.08 * s, color)
			ci.draw_circle(c + Vector2(-0.2, 0.65) * s, 0.06 * s, color)
		"quiet":
			# A few calm stars.
			for p in [Vector2(-0.35, -0.3), Vector2(0.4, -0.05), Vector2(-0.1, 0.45)]:
				var sc: Vector2 = c + p * s
				var rr := 0.28 * s
				ci.draw_colored_polygon(PackedVector2Array([sc + Vector2(0, -rr), sc + Vector2(rr * 0.3, -rr * 0.3), sc + Vector2(rr, 0),
					sc + Vector2(rr * 0.3, rr * 0.3), sc + Vector2(0, rr), sc + Vector2(-rr * 0.3, rr * 0.3), sc + Vector2(-rr, 0),
					sc + Vector2(-rr * 0.3, -rr * 0.3)]), color)
		"waypoint":
			ci.draw_polyline(_poly(c, s, [Vector2(0, -0.8), Vector2(0.8, 0), Vector2(0, 0.8), Vector2(-0.8, 0), Vector2(0, -0.8)]), color, w, true)
			ci.draw_circle(c, 0.2 * s, color)
		"destination":
			ci.draw_circle(c, 0.62 * s, Color("2f6fb5"))
			ci.draw_circle(c + Vector2(-0.18, -0.12) * s, 0.25 * s, color)
			ci.draw_circle(c + Vector2(0.22, 0.2) * s, 0.16 * s, color)
			var ring := PackedVector2Array()
			for i in 33:
				var a := TAU * i / 32.0
				ring.append(c + Vector2(cos(a) * 0.98, sin(a) * 0.3).rotated(-0.35) * s)
			ci.draw_polyline(ring, color.lightened(0.3), w * 0.8, true)
		"corporate":
			ci.draw_arc(c + Vector2(0, -0.35) * s, 0.3 * s, PI, TAU, 12, color, w)
			ci.draw_rect(Rect2(c + Vector2(-0.85, -0.35) * s, Vector2(1.7, 1.1) * s), color)
			ci.draw_line(c + Vector2(-0.85, 0.1) * s, c + Vector2(0.85, 0.1) * s, dark, w)
		"navy":
			var star := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + TAU * i / 10.0
				var r := 0.95 if i % 2 == 0 else 0.4
				star.append(c + Vector2(cos(a), sin(a)) * r * s)
			ci.draw_colored_polygon(star, color)
		"smuggler":
			ci.draw_rect(Rect2(c - Vector2(0.75, 0.75) * s, Vector2(1.5, 1.5) * s), color)
			ci.draw_rect(Rect2(c - Vector2(0.75, 0.75) * s, Vector2(1.5, 1.5) * s), dark, false, w)
			ci.draw_line(c + Vector2(-0.75, -0.75) * s, c + Vector2(0.75, 0.75) * s, dark, w)
			ci.draw_line(c + Vector2(0.75, -0.75) * s, c + Vector2(-0.75, 0.75) * s, dark, w)
		_:
			ci.draw_circle(c, 0.6 * s, color)
