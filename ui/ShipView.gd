class_name ShipView
extends Control
## Animated view of your ship. Flame length follows the thrust setting; damage shows sparks.

const FLAME_BY_THRUST := {"none": 0.0, "cruise": 32.0, "burn": 58.0, "overdrive": 92.0}

var damaged := false
var _flame := 32.0
var _target := 32.0
var _t := 0.0
var _glow: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_thrust(key: String) -> void:
	_target = FLAME_BY_THRUST.get(key, 32.0)
	if key == "none":
		_flame = 0.0


func _process(delta: float) -> void:
	_t += delta
	_flame = lerpf(_flame, _target, clampf(delta * 3.0, 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	var sc := minf(size.x / 340.0, size.y / 125.0)
	var pos := Vector2(size.x * 0.56, size.y * 0.5 + sin(_t * 1.4) * 4.0)
	# Soft glow under the ship.
	if _glow == null:
		_glow = Starfield.make_glow_texture()
	var gr := 110.0 * sc
	draw_texture_rect(_glow, Rect2(pos - Vector2(gr, gr), Vector2(gr, gr) * 2.0), false, Color(0.4, 0.6, 1.0, 0.12))
	ShipArt.draw_ship(self, pos, sc, _flame, _t, damaged)
