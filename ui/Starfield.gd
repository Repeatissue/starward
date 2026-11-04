class_name Starfield
extends Control
## Animated parallax starfield with nebula clouds. Lives behind every screen.
## Call boost() for a warp-speed burst (e.g. when the ship travels).

## [scroll factor, star size, count] per layer.
const LAYERS := [[0.15, 0.9, 150], [0.4, 1.4, 70], [1.0, 2.1, 28]]
const NEBULAE := [
	[Vector2(0.18, 0.3), 0.45, Color(0.55, 0.25, 0.75)],
	[Vector2(0.82, 0.72), 0.5, Color(0.15, 0.55, 0.65)],
	[Vector2(0.55, 0.1), 0.35, Color(0.25, 0.35, 0.85)],
]

var target_speed := 10.0
var _speed := 10.0
var _stars: Array = []
var _offsets: Array = [0.0, 0.0, 0.0]
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for li in LAYERS.size():
		for i in int(LAYERS[li][2]):
			_stars.append([Vector2(rng.randf(), rng.randf()), li, rng.randf() * TAU])


func boost(amount: float = 450.0) -> void:
	_speed = maxf(_speed, amount)


func _process(delta: float) -> void:
	_t += delta
	_speed = lerpf(_speed, target_speed, clampf(delta * 1.5, 0.0, 1.0))
	for li in LAYERS.size():
		_offsets[li] += _speed * float(LAYERS[li][0]) * delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var top := Color("0b1230")
	var bottom := Color("04050d")
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([top, top, bottom, bottom]))
	for n in NEBULAE:
		var nc := Vector2(n[0].x * w, n[0].y * h)
		var nr: float = n[1] * maxf(w, h)
		for k in 7:
			draw_circle(nc, nr * (1.0 - k * 0.13), Color(n[2], 0.022))
	for s in _stars:
		var li: int = s[1]
		var p: Vector2 = s[0]
		var x := fposmod(p.x * w - float(_offsets[li]), w)
		var y := p.y * h
		var twinkle := 0.65 + 0.35 * sin(_t * 1.5 + float(s[2]))
		var col := Color(0.85, 0.9, 1.0, (0.35 + 0.25 * li) * twinkle)
		var star_size: float = LAYERS[li][1]
		var streak := _speed * float(LAYERS[li][0]) * 0.05
		if streak > 2.0:
			draw_line(Vector2(x, y), Vector2(x + streak, y), col, star_size)
		else:
			draw_circle(Vector2(x, y), star_size * 0.6, col)
