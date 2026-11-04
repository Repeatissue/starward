class_name EventArt
extends Control
## A small animated illustration for an event, drawn in code.
## Set an event's "art" field in JSON to one of the keys in PALETTES.

const PALETTES := {
	"asteroids": [Color("0b1020"), Color("1e1a26")],
	"station": [Color("0b1530"), Color("15284a")],
	"wreck": [Color("120a14"), Color("2a0f14")],
	"crew": [Color("1a1220"), Color("2e1f18")],
	"cryo": [Color("08162a"), Color("0e2a3d")],
	"signal": [Color("0b1020"), Color("142040")],
	"trade": [Color("0b1020"), Color("1c2a24")],
	"sun": [Color("1f0c06"), Color("552808")],
	"suns": [Color("1f0c06"), Color("552808")],
	"ship": [Color("0b1020"), Color("1f1530")],
	"planet": [Color("050a1a"), Color("0d2340")],
	"storm": [Color("1a0b2e"), Color("3a1450")],
	"hydro": [Color("0d1a10"), Color("1a3320")],
	"void": [Color("02030a"), Color("0b1020")],
}

var art := "void"
var _seed := 0
var _t := 0.0
var _since_redraw := 1.0


func _init(p_art: String = "void", seed_text: String = "") -> void:
	art = p_art if PALETTES.has(p_art) else "void"
	_seed = hash(seed_text)
	custom_minimum_size = Vector2(0, 190)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Redraw at ~30 fps: plenty for gentle animation, half the cost on high-refresh screens.
func _process(delta: float) -> void:
	_t += delta
	_since_redraw += delta
	if _since_redraw >= 1.0 / 30.0:
		_since_redraw = 0.0
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var pal: Array = PALETTES[art]
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([pal[0], pal[0], pal[1], pal[1]]))
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for i in 70:
		var p := Vector2(rng.randf() * w, rng.randf() * h)
		var a := (0.25 + 0.5 * rng.randf()) * (0.6 + 0.4 * sin(_t * 2.0 + i))
		draw_circle(p, rng.randf_range(0.6, 1.6), Color(1, 1, 1, a))
	match art:
		"asteroids": _asteroids(w, h, rng)
		"station": _station(w, h)
		"wreck": _wreck(w, h, rng)
		"crew": _crew(w, h)
		"cryo": _cryo(w, h)
		"signal": _signal(w, h)
		"trade": _trade(w, h)
		"sun": _sun(w, h, false)
		"suns": _sun(w, h, true)
		"ship": ShipArt.draw_ship(self, Vector2(w * 0.5, h * 0.5), minf(w / 320.0, h / 130.0) * 0.75, 20.0, _t, true)
		"planet": _planet(w, h)
		"storm": _storm(w, h, rng)
		"hydro": _hydro(w, h)
		_: ShipArt.draw_ship(self, Vector2(w * 0.5, h * 0.5), 0.14, 12.0, _t)
	draw_rect(Rect2(0, h - 3, w, 3), Color(UIKit.ACCENT, 0.6))


func _asteroids(w: float, h: float, rng: RandomNumberGenerator) -> void:
	ShipArt.draw_ship(self, Vector2(w * 0.18, h * 0.55), 0.3, 30.0, _t)
	for i in 9:
		var c := Vector2(w * (0.36 + 0.075 * i) + sin(_t * 0.4 + i) * 6.0, h * rng.randf_range(0.15, 0.85))
		var r := rng.randf_range(10.0, 34.0)
		var pts := PackedVector2Array()
		var spin := _t * 0.2 * (1.0 if i % 2 == 0 else -1.0)
		for k in 9:
			var a := TAU * k / 9.0 + spin
			pts.append(c + Vector2(cos(a), sin(a)) * r * rng.randf_range(0.72, 1.0))
		draw_colored_polygon(pts, Color("5d5048"))
		draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.28, Color("8a7a6a"))


func _station(w: float, h: float) -> void:
	var c := Vector2(w * 0.62, h * 0.5)
	var r := h * 0.34
	var rot := _t * 0.15
	for i in 6:
		var a := rot + TAU * i / 6.0
		draw_line(c, c + Vector2(cos(a), sin(a)) * r, Color("6b7891"), 4.0)
	draw_arc(c, r, 0, TAU, 64, Color("8f9bb3"), 12.0, true)
	draw_arc(c, r - 7.0, 0, TAU, 64, Color("4a5570"), 3.0, true)
	draw_circle(c, r * 0.22, Color("aab4c8"))
	for i in 12:
		var a := rot + TAU * i / 12.0
		var on := int(_t * 2.0 + i) % 3 == 0
		draw_circle(c + Vector2(cos(a), sin(a)) * r, 3.0, UIKit.ACCENT if on else Color("ffe9b0", 0.3))
	ShipArt.draw_ship(self, Vector2(w * 0.17 + sin(_t * 0.5) * 6.0, h * 0.6), 0.24, 18.0, _t)


func _wreck(w: float, h: float, rng: RandomNumberGenerator) -> void:
	var glow := 0.25 + 0.15 * sin(_t * 3.0)
	draw_circle(Vector2(w * 0.53, h * 0.55), 60.0, Color(1, 0.3, 0.2, glow * 0.4))
	draw_set_transform(Vector2(w * 0.45, h * 0.48), 0.3 + sin(_t * 0.3) * 0.03, Vector2(0.7, 0.7))
	draw_colored_polygon(PackedVector2Array([Vector2(132, 0), Vector2(92, -22), Vector2(10, -25), Vector2(0, 10), Vector2(20, 22), Vector2(92, 22)]), Color("6b7280"))
	draw_set_transform(Vector2(w * 0.55, h * 0.6), -0.5 + sin(_t * 0.25) * 0.03, Vector2(0.7, 0.7))
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -25), Vector2(-62, -26), Vector2(-92, -17), Vector2(-92, 17), Vector2(-62, 26), Vector2(-5, 20)]), Color("4b5260"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in 14:
		var p := Vector2(w * rng.randf_range(0.3, 0.8), h * rng.randf_range(0.2, 0.8)) + Vector2(sin(_t * 0.5 + i), cos(_t * 0.4 + i)) * 4.0
		draw_rect(Rect2(p, Vector2(rng.randf_range(2, 6), rng.randf_range(2, 5))), Color("9aa3b5"))


func _crew(w: float, h: float) -> void:
	draw_circle(Vector2(w * 0.5, -h * 0.1), h * 0.6, Color(UIKit.ACCENT, 0.12))
	draw_rect(Rect2(w * 0.12, h * 0.12, w * 0.76, h * 0.42), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(w * 0.12, h * 0.12, w * 0.76, h * 0.42), Color("3a3040"), false, 4.0)
	for i in 3:
		var x := w * (0.3 + 0.2 * i)
		var head := Vector2(x, h * 0.58 + (6.0 if i == 1 else 0.0))
		draw_colored_polygon(Icons.arc_pts(Vector2(x, h * 1.04), h * 0.3, PI, TAU, 18), Color("1a1420"))
		draw_circle(head, h * 0.13, Color("1a1420"))
		draw_arc(head, h * 0.13, PI * 0.9, PI * 1.6, 12, Color(UIKit.ACCENT, 0.7), 2.5, true)


func _cryo(w: float, h: float) -> void:
	draw_rect(Rect2(0, h * 0.86, w, h * 0.14), Color("0a1220"))
	for i in 5:
		var x := w * (0.12 + 0.19 * i)
		var alarm := i == 2
		var pod := Color("2a3550")
		draw_rect(Rect2(x - 22, h * 0.22, 44, h * 0.56), pod)
		draw_circle(Vector2(x, h * 0.22), 22, pod)
		draw_circle(Vector2(x, h * 0.78), 22, pod)
		var glow := Color(1, 0.3, 0.3, 0.35 + 0.4 * absf(sin(_t * 4.0))) if alarm else Color(0.45, 0.85, 1.0, 0.45 + 0.1 * sin(_t * 2.0 + i))
		draw_rect(Rect2(x - 13, h * 0.2, 26, h * 0.55), glow)
		draw_circle(Vector2(x, h * 0.85), 3.0, UIKit.BAD if alarm else UIKit.GOOD)


func _signal(w: float, h: float) -> void:
	var src := Vector2(w * 0.86, h * 0.3)
	for k in 4:
		draw_circle(src, 14.0 - k * 3.0, Color(1, 1, 1, 0.15 + k * 0.2))
	for i in 5:
		var radius := fposmod(_t * 70.0 + i * 60.0, 300.0)
		draw_arc(src, radius, PI * 0.55, PI * 1.25, 28, Color(UIKit.INFO, 1.0 - radius / 300.0), 3.0, true)
	var dish := Vector2(w * 0.2, h * 0.62)
	draw_line(dish, dish + Vector2(0, h * 0.35), Color("8f9bb3"), 5.0)
	draw_arc(dish, 42.0, PI * 0.25, PI * 1.25, 20, Color("c9d1e0"), 7.0, true)
	draw_line(dish, dish + Vector2(26, -26), Color("c9d1e0"), 3.0)
	draw_circle(dish + Vector2(26, -26), 4.0, UIKit.ACCENT)


func _trade(w: float, h: float) -> void:
	ShipArt.draw_ship(self, Vector2(w * 0.3, h * 0.55), 0.36, 14.0, _t)
	ShipArt.draw_ship(self, Vector2(w * 0.72, h * 0.48), 0.32, 14.0, _t + 0.7, false, Color("d4a373"), true)
	var a := 0.4 + 0.4 * sin(_t * 3.0)
	draw_dashed_line(Vector2(w * 0.4, h * 0.52), Vector2(w * 0.62, h * 0.5), Color(UIKit.GOOD, a), 2.0, 6.0)


func _sun(w: float, h: float, twin: bool) -> void:
	var c := Vector2(w * 0.78, h * 0.42)
	var r := h * 0.34
	for k in 8:
		draw_circle(c, r * (1.6 - k * 0.08), Color(1.0, 0.6, 0.2, 0.05))
	for i in 12:
		var a := _t * 0.2 + TAU * i / 12.0
		draw_line(c + Vector2(cos(a), sin(a)) * r * 1.05, c + Vector2(cos(a), sin(a)) * r * (1.35 + 0.1 * sin(_t * 2.0 + i)), Color(1, 0.8, 0.4, 0.4), 3.0)
	draw_circle(c, r, Color("ffb347"))
	draw_circle(c, r * 0.75, Color("ffd27f"))
	if twin:
		var c2 := Vector2(w * 0.5, h * 0.78)
		draw_circle(c2, r * 0.75, Color(1, 0.5, 0.3, 0.15))
		draw_circle(c2, r * 0.5, Color("ff8a65"))
	else:
		draw_arc(c, r * 1.25, -PI * 0.9, -PI * 0.35, 20, Color(1, 0.85, 0.5, 0.6 + 0.3 * sin(_t * 4.0)), 6.0, true)
	ShipArt.draw_ship(self, Vector2(w * 0.16, h * 0.6), 0.2, 20.0, _t)


func _planet(w: float, h: float) -> void:
	for band in 3:
		var pts := PackedVector2Array()
		for i in 41:
			var x := w * i / 40.0
			pts.append(Vector2(x, h * 0.22 + band * 16.0 + sin(x * 0.015 + _t + band) * 12.0))
		var col := Color(0.4, 1.0, 0.6, 0.35) if band != 1 else Color(0.75, 0.45, 1.0, 0.35)
		draw_polyline(pts, col, 8.0, true)
	var c := Vector2(w * 0.5, h * 1.9)
	var r := h * 1.35
	draw_circle(c, r * 1.04, Color(0.45, 0.75, 1.0, 0.15))
	draw_circle(c, r, Color("1d4e89"))
	draw_circle(c + Vector2(-r * 0.25, -r * 0.88), r * 0.12, Color("3fa34d"))
	draw_circle(c + Vector2(r * 0.2, -r * 0.92), r * 0.08, Color("3fa34d"))
	draw_circle(c + Vector2(r * 0.05, -r * 0.95), r * 0.06, Color(1, 1, 1, 0.5))


func _storm(w: float, h: float, rng: RandomNumberGenerator) -> void:
	for i in 9:
		var c := Vector2(w * rng.randf(), h * rng.randf()) + Vector2(sin(_t * 0.3 + i) * 10.0, 0)
		draw_circle(c, rng.randf_range(40, 90), Color(0.6, 0.3, 0.9, 0.12))
	for i in 3:
		var pts := PackedVector2Array()
		var x := w * rng.randf_range(0.15, 0.85)
		for k in 7:
			pts.append(Vector2(x + rng.randf_range(-25, 25), h * k / 6.0))
		if fmod(_t * 0.8 + i * 0.37, 1.0) < 0.12:
			draw_polyline(pts, Color(0.85, 0.75, 1.0, 0.95), 3.0, true)
	ShipArt.draw_ship(self, Vector2(w * 0.5, h * 0.55), 0.26, 24.0, _t)


func _hydro(w: float, h: float) -> void:
	draw_rect(Rect2(w * 0.08, 10, w * 0.84, 8), Color(1.0, 0.5, 0.85, 0.8))
	draw_rect(Rect2(w * 0.08, 18, w * 0.84, h * 0.5), Color(1.0, 0.5, 0.85, 0.06))
	draw_rect(Rect2(w * 0.06, h * 0.84, w * 0.88, 14), Color("3a2e22"))
	for i in 10:
		var x := w * (0.11 + i * 0.087)
		var top := h * (0.3 + 0.08 * sin(i * 1.7))
		var sway := sin(_t * 1.2 + i) * 4.0
		draw_line(Vector2(x, h * 0.84), Vector2(x + sway, top), Color("4c8a3a"), 3.0)
		for k in 3:
			var ly := lerpf(h * 0.84, top, 0.3 + k * 0.3)
			var side := -1.0 if (k + i) % 2 == 0 else 1.0
			draw_circle(Vector2(x + sway * (0.3 + k * 0.3) + side * 9.0, ly), 7.0, Color("7cc36a"))
		draw_circle(Vector2(x + sway, top), 5.0, Color("ff8a65") if i % 3 == 0 else Color("9be07f"))
