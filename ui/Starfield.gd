class_name Starfield
extends Control
## Parallax starfield with nebula clouds, behind every screen.
## Performance: every layer is drawn ONCE and scrolled by moving it, so the starfield costs
## almost nothing per frame. Layers only re-draw during a warp burst (to show streaks).

## [scroll factor, star size, count] per layer.
const LAYERS := [[0.15, 0.9, 150], [0.4, 1.4, 70], [1.0, 2.1, 28]]
const NEBULAE := [
	[Vector2(0.18, 0.3), 0.45, Color(0.55, 0.25, 0.75)],
	[Vector2(0.82, 0.72), 0.5, Color(0.15, 0.55, 0.65)],
	[Vector2(0.55, 0.1), 0.35, Color(0.25, 0.35, 0.85)],
]

var target_speed := 10.0
var _speed := 10.0
var _t := 0.0
var _layers: Array = []
var _offsets: Array = []
var _glow: GradientTexture2D


class StarLayer extends Control:
	var stars: PackedVector2Array
	var star_size := 1.0
	var alpha := 0.5
	var streak := 0.0

	func _draw() -> void:
		var w := size.x * 0.5  # layer is two screens wide so it can wrap seamlessly
		var col := Color(0.85, 0.9, 1.0, alpha)
		for p in stars:
			for copy in 2:
				var pos := Vector2(p.x * w + copy * w, p.y * size.y)
				if streak > 2.0:
					draw_line(pos, pos + Vector2(streak, 0), col, star_size)
				else:
					draw_rect(Rect2(pos - Vector2.ONE * star_size * 0.6, Vector2.ONE * star_size * 1.2), col)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glow = make_glow_texture()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for li in LAYERS.size():
		var layer := StarLayer.new()
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.star_size = LAYERS[li][1]
		layer.alpha = 0.35 + 0.25 * li
		for i in int(LAYERS[li][2]):
			layer.stars.append(Vector2(rng.randf(), rng.randf()))
		add_child(layer)
		_layers.append(layer)
		_offsets.append(0.0)
	resized.connect(_on_resized)
	_on_resized()


## A soft radial glow (white centre fading to transparent). One quad replaces many stacked circles.
static func make_glow_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.35))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex


func _on_resized() -> void:
	for layer in _layers:
		layer.size = Vector2(size.x * 2.0, size.y)
		layer.queue_redraw()
	queue_redraw()


func boost(amount: float = 450.0) -> void:
	_speed = maxf(_speed, amount)


func _process(delta: float) -> void:
	_t += delta
	_speed = lerpf(_speed, target_speed, clampf(delta * 1.5, 0.0, 1.0))
	for li in _layers.size():
		var layer: StarLayer = _layers[li]
		var factor: float = LAYERS[li][0]
		_offsets[li] = fposmod(float(_offsets[li]) + _speed * factor * delta, size.x)
		layer.position.x = -float(_offsets[li])
		layer.modulate.a = 0.85 + 0.15 * sin(_t * (0.8 + li * 0.5) + li)
		var streak := _speed * factor * 0.05
		if streak > 2.0 or layer.streak > 2.0:
			layer.streak = streak
			layer.queue_redraw()


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
		draw_texture_rect(_glow, Rect2(nc - Vector2(nr, nr), Vector2(nr, nr) * 2.0), false, Color(n[2], 0.16))
