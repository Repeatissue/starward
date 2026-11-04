class_name RouteMap
extends Control
## The whole journey at a glance: sectors, stops (with icons) and your ship's position.
## Performance: the map (with all its text) only re-draws when refresh() is called.
## Only the small ship marker and pulse ring animate every frame, on a child layer.

const SECTOR_TINTS := [Color("6ec6ff"), Color("c792ea"), Color("ff8a65"), Color("7fd18b")]

var _marker: Marker
var _ship_pos := Vector2.ZERO
var _current_pos := Vector2.ZERO
var _current_r := 14.0


class Marker extends Control:
	var map: RouteMap
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var p := map._current_pos
		draw_arc(p, map._current_r + 5.0 + 2.0 * sin(_t * 3.0), 0, TAU, 32, Color(UIKit.ACCENT, 0.8), 2.0, true)
		ShipArt.draw_ship(self, map._ship_pos + Vector2(0, sin(_t * 2.0) * 1.5), 0.17, 22.0, _t)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker = Marker.new()
	_marker.map = self
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_marker)
	resized.connect(refresh)


## Call whenever the journey state changes (travel, arrival, load).
func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	var route: Array = GameState.route
	if route.is_empty():
		return
	var font := get_theme_default_font()
	var total := maxf(GameState.total_distance(), 1.0)
	var left := 34.0
	var right := size.x - 34.0
	var y := size.y * 0.56
	var xs: Array = []
	var cum := 0.0
	for n in route:
		cum += float(n["distance"])
		xs.append(left + (right - left) * cum / total)

	# Sector bands
	var i := 0
	while i < route.size():
		var sec := int(route[i]["sector"])
		var j := i
		while j + 1 < route.size() and int(route[j + 1]["sector"]) == sec:
			j += 1
		var x0: float = xs[i] - 24.0
		var x1: float = xs[j] + 24.0
		var tint: Color = SECTOR_TINTS[(sec - 1) % SECTOR_TINTS.size()]
		var band := Rect2(x0, 2, x1 - x0, size.y - 4)
		draw_rect(band, Color(tint, 0.06))
		draw_rect(band, Color(tint, 0.22), false, 1.0)
		draw_string(font, Vector2(x0 + 8, 16), str(route[i]["sector_name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, x1 - x0 - 12, 11, Color(tint, 0.85))
		i = j + 1

	# Path: dashed ahead, solid behind
	var idx := GameState.node_index
	var ship_x: float = xs[idx]
	if idx + 1 < route.size():
		var leg := maxf(float(route[idx + 1]["distance"]), 0.01)
		ship_x = lerpf(xs[idx], xs[idx + 1], clampf(GameState.progress / leg, 0.0, 1.0))
	draw_dashed_line(Vector2(xs[0], y), Vector2(xs[xs.size() - 1], y), Color(UIKit.DIM, 0.6), 2.0, 8.0)
	draw_line(Vector2(xs[0], y), Vector2(ship_x, y), UIKit.ACCENT, 4.0, true)
	_ship_pos = Vector2(ship_x, y - 28)

	# Stops
	for k in route.size():
		var n: Dictionary = route[k]
		var p := Vector2(xs[k], y)
		var kind: String = n["type"]
		var r := 20.0 if kind == "destination" else 14.0
		var col := Icons.color_for(kind)
		if k < idx:
			col = col.darkened(0.55)
		draw_circle(p, r, Color("0b1020"))
		draw_arc(p, r, 0, TAU, 28, col, 2.0, true)
		Icons.draw(self, kind, Rect2(p - Vector2(r, r) * 0.62, Vector2(r, r) * 1.24), col)
		if k == idx:
			_current_pos = p
			_current_r = r

	# Labels for where you are, where you're going, and the goal
	_label(font, xs[idx], y + 38, str(route[idx]["name"]), UIKit.ACCENT)
	if idx + 1 < route.size():
		var ny := y + 38.0
		if absf(xs[idx + 1] - xs[idx]) < 150.0:
			ny += 16.0
		_label(font, xs[idx + 1], ny, "Next: " + str(route[idx + 1]["name"]), UIKit.TEXT)
	var last := route.size() - 1
	if last > idx + 1:
		_label(font, xs[last], y + 38, "EARTH 2", UIKit.GOOD)


func _label(font: Font, x: float, y: float, text: String, color: Color) -> void:
	var w := 180.0
	var lx := clampf(x - w / 2.0, 0.0, size.x - w)
	draw_string(font, Vector2(lx, y), text, HORIZONTAL_ALIGNMENT_CENTER, w, 13, color)
