class_name ShipArt
extends RefCounted
## Draws the colony ship (nose points right). Unit size is about 240 x 100 at scale 1.

const HULL := Color("c9d1e0")


static func draw_ship(ci: CanvasItem, pos: Vector2, scale: float, flame: float, t: float,
		damaged: bool = false, tint: Color = HULL, flip: bool = false) -> void:
	ci.draw_set_transform(pos, 0.0, Vector2(-scale if flip else scale, scale))
	var dark := tint.darkened(0.45)

	# Engine flame (turns blue-white at high thrust).
	if flame > 0.0:
		var fl := flame * (0.85 + 0.12 * sin(t * 37.0) + 0.05 * sin(t * 13.0))
		var outer := Color(1.0, 0.55, 0.2, 0.85) if flame < 70.0 else Color(0.45, 0.72, 1.0, 0.9)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-104, -12), Vector2(-104 - fl, 0), Vector2(-104, 12)]), outer)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-104, -6), Vector2(-104 - fl * 0.55, 0), Vector2(-104, 6)]), Color(1, 0.95, 0.8, 0.95))

	# Fins
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-40, -24), Vector2(-92, -52), Vector2(-78, -22)]), dark)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-40, 24), Vector2(-78, 22), Vector2(-92, 52)]), dark)

	# Cryo spines with glowing pods
	ci.draw_rect(Rect2(-58, -37, 98, 13), dark)
	ci.draw_rect(Rect2(-58, 24, 98, 13), dark)
	for i in 4:
		var glow := Color(0.5, 0.88, 1.0, 0.75 + 0.25 * sin(t * 2.0 + i))
		ci.draw_circle(Vector2(-46 + i * 25, -30.5), 4.5, glow)
		ci.draw_circle(Vector2(-46 + i * 25, 30.5), 4.5, glow)

	# Main body
	ci.draw_colored_polygon(PackedVector2Array([Vector2(132, 0), Vector2(92, -22), Vector2(-62, -26), Vector2(-92, -17),
		Vector2(-92, 17), Vector2(-62, 26), Vector2(92, 22)]), tint)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(132, 0), Vector2(92, 22), Vector2(-62, 26), Vector2(-92, 17),
		Vector2(-92, 8), Vector2(110, 6)]), Color(0, 0, 0, 0.18))
	ci.draw_rect(Rect2(-60, -4, 140, 7), UIKit.ACCENT.darkened(0.1))
	ci.draw_rect(Rect2(-106, -14, 16, 28), dark.darkened(0.3))

	# Cockpit
	ci.draw_colored_polygon(PackedVector2Array([Vector2(118, -4), Vector2(98, -15), Vector2(84, -15), Vector2(90, -4)]), Color(0.55, 0.85, 1.0))

	# Blinking nav light
	if fmod(t, 1.6) < 0.25:
		ci.draw_circle(Vector2(-90, -50), 3.5, Color(1, 0.3, 0.3))

	if damaged:
		ci.draw_polyline(PackedVector2Array([Vector2(10, -24), Vector2(18, -10), Vector2(8, 2), Vector2(20, 14)]), Color(0.1, 0.1, 0.12), 2.5)
		ci.draw_polyline(PackedVector2Array([Vector2(-30, 24), Vector2(-24, 12), Vector2(-34, 4)]), Color(0.1, 0.1, 0.12), 2.5)
		if fmod(t * 3.0, 1.0) < 0.4:
			ci.draw_circle(Vector2(18, -10), 3.0, Color(1, 0.85, 0.4))
			ci.draw_circle(Vector2(24, -16), 1.8, Color(1, 0.6, 0.2))

	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
