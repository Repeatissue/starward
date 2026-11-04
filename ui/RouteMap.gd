class_name RouteMap
extends Control
## The branching star map: sectors, every stop (with icons), the path taken and the ship.
## Used small at the top of the travel screen, and large in the route chooser.
## Performance: the map (with all its text) only re-draws when refresh() is called.
## Only the ship marker and pulse rings animate every frame, on a child layer.

const SECTOR_TINTS := [Color("6ec6ff"), Color("c792ea"), Color("ff8a65"), Color("7fd18b")]

## Stop to emphasise (the option the player is looking at in the route chooser).
var highlight_id := "":
	set(v):
		highlight_id = v
		refresh()
## Show names under every stop that can be reached next (route chooser), not just the current one.
var label_options := false
var node_radius := 10.0

var _marker: Marker
var _pos := {}
var _ship_pos := Vector2.ZERO
var _current_pos := Vector2.ZERO
var _pulse_ids: Array = []


class Marker extends Control:
	var map: RouteMap
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var r := map.node_radius
		draw_arc(map._current_pos, r + 5.0 + 2.0 * sin(_t * 3.0), 0, TAU, 32, Color(UIKit.ACCENT, 0.8), 2.0, true)
		for id in map._pulse_ids:
			if map._pos.has(id):
				var a := 0.35 + 0.35 * sin(_t * 4.0)
				draw_arc(map._pos[id], r + 4.0, 0, TAU, 28, Color(UIKit.INFO, a), 2.0, true)
		ShipArt.draw_ship(self, map._ship_pos + Vector2(0, sin(_t * 2.0) * 1.5), r * 0.016, 20.0, _t)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker = Marker.new()
	_marker.map = self
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_marker)
	resized.connect(refresh)


## Call whenever the journey state changes (travel, arrival, route choice, load).
func refresh() -> void:
	queue_redraw()


func _layout() -> void:
	_pos.clear()
	var nodes: Dictionary = GameState.star_map.get("nodes", {})
	var cols := maxi(int(GameState.star_map.get("columns", 1)) - 1, 1)
	var left := 30.0
	var right := size.x - 30.0
	var top := 26.0
	var bottom := size.y - 26.0
	for id in nodes:
		var n: Dictionary = nodes[id]
		var x := left + (right - left) * float(n["col"]) / cols
		var y := lerpf(top, bottom, (float(n["row"]) + 0.5) / float(n["rows"]))
		_pos[id] = Vector2(x, y)


func _draw() -> void:
	var nodes: Dictionary = GameState.star_map.get("nodes", {})
	if nodes.is_empty() or GameState.route.is_empty():
		return
	_layout()
	var font := get_theme_default_font()
	var cur: Dictionary = GameState.current_node()
	var cur_id: String = cur["id"]
	var cur_col := int(cur["col"])
	var nxt := GameState.next_node()
	var taken := {}
	for n in GameState.route:
		taken[n["id"]] = true
	var options: Array = cur.get("next", []) if nxt.is_empty() else []

	# Sector bands
	var bands := {}
	for id in nodes:
		var n: Dictionary = nodes[id]
		var s := int(n["sector"])
		var x: float = _pos[id].x
		if not bands.has(s):
			bands[s] = [x, x, n["sector_name"]]
		bands[s][0] = minf(bands[s][0], x)
		bands[s][1] = maxf(bands[s][1], x)
	for s in bands:
		var tint: Color = SECTOR_TINTS[(int(s) - 1) % SECTOR_TINTS.size()]
		var band := Rect2(bands[s][0] - 20.0, 2, bands[s][1] - bands[s][0] + 40.0, size.y - 4)
		draw_rect(band, Color(tint, 0.05))
		draw_rect(band, Color(tint, 0.2), false, 1.0)
		draw_string(font, Vector2(band.position.x + 6, 15), str(bands[s][2]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, band.size.x - 10, 10, Color(tint, 0.85))

	# Lanes: faint for the rest of the map, amber for the path taken, bright for the options now.
	for id in nodes:
		for nid in nodes[id]["next"]:
			var a: Vector2 = _pos[id]
			var b: Vector2 = _pos[nid]
			var col := Color(UIKit.DIM, 0.18)
			var w := 1.5
			if int(nodes[id]["col"]) < cur_col:
				col = Color(UIKit.DIM, 0.08)
			if taken.has(id) and taken.has(nid):
				col = UIKit.ACCENT
				w = 3.0
			elif id == cur_id and (nid in options):
				col = Color(UIKit.INFO, 0.9 if nid == highlight_id else 0.45)
				w = 3.0 if nid == highlight_id else 2.0
			draw_line(a, b, col, w, true)

	# Stops
	for id in nodes:
		var n: Dictionary = nodes[id]
		var kind: String = n["type"]
		var p: Vector2 = _pos[id]
		var r := node_radius * (1.5 if kind == "destination" else 1.0)
		var c := Icons.color_for(kind)
		var behind: bool = int(n["col"]) < cur_col or (int(n["col"]) == cur_col and id != cur_id)
		if behind and not taken.has(id):
			c = Color(c, 0.2)
		elif taken.has(id) and id != cur_id:
			c = c.darkened(0.45)
		elif int(n["col"]) > cur_col + 1 and not (id in options):
			c = Color(c, 0.55)
		draw_circle(p, r, Color("0b1020"))
		draw_arc(p, r, 0, TAU, 24, c, 2.0 if id != highlight_id else 3.0, true)
		Icons.draw(self, kind, Rect2(p - Vector2(r, r) * 0.62, Vector2(r, r) * 1.24), c)

	# Labels (the chooser names the current stop in its header, so it skips that label)
	if not label_options:
		_label(font, _pos[cur_id], str(cur["name"]), UIKit.ACCENT)
	if not nxt.is_empty():
		_label(font, _pos[nxt["id"]], str(nxt["name"]), UIKit.TEXT)
	elif label_options:
		for id in options:
			_label(font, _pos[id], str(nodes[id]["name"]), UIKit.INFO if id == highlight_id else UIKit.TEXT)
	elif highlight_id != "" and _pos.has(highlight_id):
		_label(font, _pos[highlight_id], str(nodes[highlight_id]["name"]), UIKit.INFO)

	# Ship position and pulse targets for the animated layer
	_current_pos = _pos[cur_id]
	_ship_pos = _current_pos + Vector2(0, -node_radius - 10.0)
	if not nxt.is_empty():
		var leg := maxf(float(nxt["distance"]), 0.01)
		_ship_pos = _current_pos.lerp(_pos[nxt["id"]], clampf(GameState.progress / leg, 0.0, 1.0)) + Vector2(0, -node_radius - 6.0)
	_pulse_ids = options.duplicate()


func _label(font: Font, p: Vector2, text: String, color: Color) -> void:
	var w := 150.0
	var lx := clampf(p.x - w / 2.0, 0.0, size.x - w)
	var ly := p.y + node_radius + 13.0
	if ly > size.y - 2.0:
		ly = p.y - node_radius - 5.0
	draw_string(font, Vector2(lx, ly), text, HORIZONTAL_ALIGNMENT_CENTER, w, 11 if node_radius < 14.0 else 14, color)
