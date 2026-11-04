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


## Flattens the sectors into one linear route (Phase 1). Branching maps come in Phase 2.
## Nodes with a "pool" (hazard, derelict, waypoint) draw a random event from that pool, seeded,
## so each run meets different hazards. The node takes the event's "place" name for the map.
func build_route() -> Array:
	var out: Array = []
	var used := {}
	for sector in sectors:
		for node in sector["nodes"]:
			var n: Dictionary = node.duplicate(true)
			n["sector"] = int(sector["id"])
			n["sector_name"] = sector["name"]
			if n.has("pool"):
				var ev := _pick_pool_event(n["pool"], n["sector"], used)
				if not ev.is_empty():
					used[ev["id"]] = true
					n["event"] = ev["id"]
					n["name"] = ev.get("place", n["name"])
			out.append(n)
	return out


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
		push_warning("No '%s' events left for sector %d" % [pool, sector])
		return {}
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
