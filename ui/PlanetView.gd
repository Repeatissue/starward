class_name PlanetView
extends Control
## Earth 2: a slowly rotating planet with clouds, atmosphere glow and (optionally) an orbiting ship.

const OCEAN := Color("1d4e89")
const LAND := Color("3fa34d")
const LAND_LIGHT := Color("7cc36a")
## Continents as blobs: Vector3(longitude, latitude, size).
const CONTINENTS := [
	Vector3(0.0, -0.3, 0.28), Vector3(0.25, -0.15, 0.22), Vector3(0.15, -0.45, 0.16),
	Vector3(1.9, 0.25, 0.3), Vector3(2.2, 0.4, 0.2), Vector3(1.7, 0.05, 0.18),
	Vector3(3.6, -0.1, 0.26), Vector3(3.9, 0.2, 0.2), Vector3(4.8, 0.55, 0.18),
	Vector3(5.4, -0.5, 0.14), Vector3(0.9, 0.6, 0.12),
]
const CLOUDS := [
	Vector3(0.5, -0.2, 0.2), Vector3(1.4, 0.35, 0.16), Vector3(2.8, -0.4, 0.22),
	Vector3(4.2, 0.1, 0.18), Vector3(5.6, 0.45, 0.15),
]

var show_ship := false
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.33
	var ship_a := _t * 0.3
	var ship_pos := c + Vector2(cos(ship_a) * r * 1.22, sin(ship_a) * r * 0.3 - r * 0.12)
	var ship_front := sin(ship_a) > 0.0
	var ship_flip := -sin(ship_a) < 0.0

	if show_ship and not ship_front:
		ShipArt.draw_ship(self, ship_pos, r / 900.0, 14.0, _t, false, ShipArt.HULL, ship_flip)

	for i in 7:
		draw_circle(c, r * (1.0 + 0.035 * (i + 1)), Color(0.45, 0.75, 1.0, 0.045))
	draw_circle(c, r, OCEAN)
	draw_circle(c + Vector2(-r * 0.25, -r * 0.25), r * 0.7, Color(0.35, 0.6, 0.95, 0.12))
	_draw_blobs(c, r, CONTINENTS, _t * 0.06, LAND, LAND_LIGHT, 7, 0.55)
	_draw_blobs(c, r, CLOUDS, _t * 0.09, Color(1, 1, 1, 0.38), Color(1, 1, 1, 0.22), 5, 0.12)

	# Night side
	var shadow := Icons.arc_pts(c, r, -PI / 2.0, PI / 2.0, 32)
	for i in 33:
		var a := PI / 2.0 - PI * i / 32.0
		shadow.append(c + Vector2(cos(a) * r * 0.3, sin(a) * r))
	draw_colored_polygon(shadow, Color(0.0, 0.01, 0.06, 0.55))
	var soft := Icons.arc_pts(c, r, -PI / 2.0, PI / 2.0, 32)
	for i in 33:
		var a := PI / 2.0 - PI * i / 32.0
		soft.append(c + Vector2(cos(a) * r * 0.05, sin(a) * r))
	draw_colored_polygon(soft, Color(0.0, 0.01, 0.06, 0.2))
	draw_arc(c, r, 0, TAU, 96, Color(0.6, 0.85, 1.0, 0.55), 3.0, true)

	if show_ship and ship_front:
		ShipArt.draw_ship(self, ship_pos, r / 900.0, 14.0, _t, false, ShipArt.HULL, ship_flip)


## Each blob is drawn as a cluster of smaller lumps so coastlines look irregular.
## `stretch` widens lumps along longitude (clouds are long and thin).
func _draw_blobs(c: Vector2, r: float, blobs: Array, rot: float, col: Color, col2: Color, lumps: int, stretch: float) -> void:
	var bi := 0
	for b in blobs:
		bi += 1
		var bsize: float = b.z
		for k in lumps:
			var ang := bi * 2.39 + k * 1.7
			var off: Vector2 = Vector2(cos(ang) * (0.5 + stretch), sin(ang) * 0.5) * bsize * 0.9
			var lon: float = b.x + off.x + rot
			var lat: float = b.y + off.y
			var front := cos(lon)
			if front <= 0.05:
				continue
			var p := c + Vector2(sin(lon) * cos(lat), sin(lat)) * r * 0.92
			var lump_size: float = bsize * (0.45 + 0.35 * fposmod(k * 0.618 + bi * 0.37, 1.0))
			var rad: float = lump_size * r * (0.3 + 0.7 * front)
			rad = minf(rad, r - p.distance_to(c))
			if rad <= 1.0:
				continue
			draw_circle(p, rad, col)
			if k % 2 == 0:
				draw_circle(p + Vector2(-rad * 0.2, -rad * 0.2), rad * 0.55, col2)
