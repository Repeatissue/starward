extends Node
## Loads all game content from res://data. Add content by editing JSON, not code.

const EVENT_FILES := [
	"res://data/events/travel_events.json",
	"res://data/events/node_events.json",
]

var items: Array = []
var backgrounds: Array = []
var sectors: Array = []
var events: Array = []
var events_by_id: Dictionary = {}


func _ready() -> void:
	items = _load_array("res://data/items.json")
	backgrounds = _load_array("res://data/backgrounds.json")
	sectors = _load_array("res://data/sectors.json")
	for path in EVENT_FILES:
		for e in _load_array(path):
			if events_by_id.has(e["id"]):
				push_warning("Duplicate event id: %s" % e["id"])
			events.append(e)
			events_by_id[e["id"]] = e


## Days to reach a stop of each type. Hazards are shortcuts; stations are detours.
const TYPE_DISTANCE := {"station": [5, 7], "hazard": [3, 4], "derelict": [4, 5], "waypoint": [5, 6], "quiet": [4, 5]}
const QUIET_NAMES := ["Quiet Lane", "Open Space", "Still Drift", "Clear Run", "Empty Reach"]


## Builds a seeded branching star map. Each sector's "layout" is a list of columns:
## "open" = 2-3 random stops, or a fixed hub stop (a Dictionary) that every path passes through.
## Each stop links to 1-3 stops in the next column. Returns:
##   {"nodes": {id: node}, "start": id, "columns": n}
## Node: {id, name, type, sector, sector_name, distance, col, row, rows, next: [ids], event?, description?}
func build_map() -> Dictionary:
	var nodes := {}
	var columns: Array = []
	var used := {}
	for sector in sectors:
		var station_pool: Array = sector.get("stations", []).duplicate(true)
		if sector.has("start"):
			var start := _new_node(sector["start"], sector, columns.size(), 0, 1, nodes.size())
			start["distance"] = 0
			nodes[start["id"]] = start
			columns.append([start["id"]])
		for entry in sector["layout"]:
			var col: Array = []
			if entry is Dictionary:
				var hub := _new_node(entry, sector, columns.size(), 0, 1, nodes.size())
				nodes[hub["id"]] = hub
				col.append(hub["id"])
			else:
				var count := RNG.range_i(2, 3)
				var types := _roll_types(sector, count)
				for r in count:
					var n := _open_node(types[r], sector, columns.size(), r, count, nodes.size(), used, station_pool)
					nodes[n["id"]] = n
					col.append(n["id"])
			columns.append(col)
	for c in columns.size() - 1:
		_connect(nodes, columns[c], columns[c + 1])
	return {"nodes": nodes, "start": columns[0][0], "columns": columns.size()}


func _new_node(src: Dictionary, sector: Dictionary, col: int, row: int, rows: int, index: int) -> Dictionary:
	var n: Dictionary = src.duplicate(true)
	n["id"] = "n%d" % index
	n["sector"] = int(sector["id"])
	n["sector_name"] = sector["name"]
	n["col"] = col
	n["row"] = row
	n["rows"] = rows
	n["next"] = []
	if not n.has("distance"):
		n["distance"] = 3
	return n


func _open_node(type: String, sector: Dictionary, col: int, row: int, rows: int, index: int, used: Dictionary, station_pool: Array) -> Dictionary:
	var src := {"type": type}
	if type == "station" and not station_pool.is_empty():
		var st: Dictionary = station_pool.pop_at(RNG.range_i(0, station_pool.size() - 1))
		src["name"] = st["name"]
		src["description"] = st.get("description", "")
	elif type in ["hazard", "derelict", "waypoint"]:
		var ev := _pick_pool_event(type, int(sector["id"]), used)
		if ev.is_empty():
			type = "quiet"
		else:
			used[ev["id"]] = true
			src["event"] = ev["id"]
			src["name"] = ev.get("place", type.capitalize())
	else:
		type = "quiet"
	if type == "quiet":
		src = {"type": "quiet", "name": RNG.pick(QUIET_NAMES), "description": "Nothing on the scopes. A calm stretch of space."}
	var n := _new_node(src, sector, col, row, rows, index)
	var span: Array = TYPE_DISTANCE[type]
	n["distance"] = RNG.range_i(int(span[0]), int(span[1]))
	return n


## Weighted stop types for one column, never all the same kind.
func _roll_types(sector: Dictionary, count: int) -> Array:
	var weights: Dictionary = sector.get("weights", {"quiet": 1})
	var pool: Array = []
	for t in weights:
		pool.append({"type": t, "weight": float(weights[t])})
	var types: Array = []
	for i in count:
		types.append(RNG.pick_weighted(pool)["type"])
	var all_same := true
	for t in types:
		if t != types[0]:
			all_same = false
	if all_same and count > 1:
		types[count - 1] = "quiet" if types[0] != "quiet" else "station"
	return types


## Link each stop to the stops roughly level with it in the next column; every stop gets
## at least one way in and one way out.
func _connect(nodes: Dictionary, a: Array, b: Array) -> void:
	for ida in a:
		var na: Dictionary = nodes[ida]
		var pa := (float(na["row"]) + 0.5) / float(na["rows"])
		for idb in b:
			var nb: Dictionary = nodes[idb]
			var pb := (float(nb["row"]) + 0.5) / float(nb["rows"])
			if absf(pa - pb) <= 0.55:
				na["next"].append(idb)
		if na["next"].is_empty():
			na["next"].append(_nearest(nodes, b, pa))
	for idb in b:
		var has_in := false
		for ida in a:
			if idb in nodes[ida]["next"]:
				has_in = true
		if not has_in:
			var nb: Dictionary = nodes[idb]
			var pb := (float(nb["row"]) + 0.5) / float(nb["rows"])
			nodes[_nearest(nodes, a, pb)]["next"].append(idb)


func _nearest(nodes: Dictionary, ids: Array, p: float) -> String:
	var best: String = ids[0]
	var best_d := INF
	for id in ids:
		var n: Dictionary = nodes[id]
		var d := absf((float(n["row"]) + 0.5) / float(n["rows"]) - p)
		if d < best_d:
			best_d = d
			best = id
	return best


func _pick_pool_event(pool: String, sector: int, used: Dictionary) -> Dictionary:
	var options: Array = []
	for e in events:
		if e.get("pool", "") != pool or used.has(e["id"]):
			continue
		if e.has("sector"):
			var ok := false
			for s in e["sector"]:
				if int(s) == sector:
					ok = true
			if not ok:
				continue
		options.append(e)
	if options.is_empty():
		return {}  # pool used up for this sector: the stop becomes quiet space
	return RNG.pick(options)


func _load_array(path: String) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Could not open %s" % path)
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		return parsed
	push_error("%s should contain a JSON array" % path)
	return []
