extends Node
## Picks events, checks choice requirements and applies outcomes.
## Event format: see data/events/*.json and the README.

const DAILY_EVENT_CHANCE := 0.18
## Repeatable events ("once": false) can't recur within this many days,
## and happen at most "max_per_run" times (default 2) in one journey.
const REPEAT_COOLDOWN_DAYS := 12
const DEFAULT_MAX_PER_RUN := 2


## Rolled once per travel day. Returns {} when nothing happens.
func roll_travel_event() -> Dictionary:
	if not RNG.chance(DAILY_EVENT_CHANCE):
		return {}
	var sector: int = GameState.current_sector()
	var pool: Array = []
	for e in Data.events:
		if e.get("trigger", "travel") != "travel":
			continue
		if not _sector_ok(e, sector):
			continue
		if not event_available(e):
			continue
		pool.append(e)
	if pool.is_empty():
		return {}
	return RNG.pick_weighted(pool)


func get_event(id: String) -> Dictionary:
	return Data.events_by_id.get(id, {})


func event_available(e: Dictionary) -> bool:
	var seen: Variant = GameState.seen_events.get(e["id"])
	if seen != null:
		if e.get("once", true):
			return false
		var count := 1
		var last_day := 0
		if seen is Dictionary:
			count = int(seen.get("count", 1))
			last_day = int(seen.get("day", 0))
		if count >= int(e.get("max_per_run", DEFAULT_MAX_PER_RUN)):
			return false
		if GameState.day - last_day < REPEAT_COOLDOWN_DAYS:
			return false
	return _requirements_met(e.get("requires", {}))


func is_choice_available(choice: Dictionary) -> bool:
	return _requirements_met(choice.get("requires", {}))


## Button text, prefixed with what the choice needs and followed by a risk hint, e.g.
## "[Medic] Treat them" or "Answer the call.  (it might be a trap)".
## Gambles (choices with random outcomes) always get a hint so risks never feel hidden.
func choice_label(choice: Dictionary) -> String:
	var req: Dictionary = choice.get("requires", {})
	var prefix := ""
	if req.has("role"):
		prefix += "[%s] " % req["role"]
	if req.has("resources"):
		for key in req["resources"]:
			prefix += "[needs %d %s] " % [int(req["resources"][key]), GameState.RESOURCE_NAMES.get(key, key)]
	var hint: String = choice.get("hint", "")
	if hint == "" and choice.has("outcomes"):
		hint = "uncertain outcome"
	elif hint == "":
		hint = _cost_summary(choice.get("effects", {}), req.get("resources", {}))
	return prefix + str(choice["text"]) + ("   (%s)" % hint if hint != "" else "")


## For choices with a fixed result, list what they cost (never what they reward),
## so there are no hidden prices. Resources already shown as a requirement are skipped.
func _cost_summary(fx: Dictionary, required: Dictionary) -> String:
	var costs: Array = []
	for key in fx:
		var v := float(fx[key]) if not (fx[key] is Dictionary) and not (fx[key] is String) else 0.0
		if key in GameState.RESOURCE_KEYS:
			if v < 0.0 and not required.has(key):
				costs.append("%d %s" % [int(-v), str(GameState.RESOURCE_NAMES[key]).to_lower()])
		else:
			match key:
				"colonists":
					if v < 0.0:
						costs.append("%d colonists" % int(-v))
				"crew_health":
					if v < 0.0:
						costs.append("%d health for every crew member" % int(-v))
				"crew_morale":
					if v < 0.0:
						costs.append("%d morale" % int(-v))
				"injure_random":
					costs.append("someone gets hurt")
				"kill_random":
					costs.append("a life")
				"days":
					costs.append(GameState.days(int(v)))
	return ("costs " + ", ".join(PackedStringArray(costs))) if not costs.is_empty() else ""


## Applies the choice (or one of its weighted outcomes).
## Returns {"text": String, "changes": Array[String]} for the popup.
func resolve_choice(event: Dictionary, choice: Dictionary) -> Dictionary:
	var prev: Variant = GameState.seen_events.get(event["id"])
	var count := int(prev.get("count", 1)) + 1 if prev is Dictionary else (2 if prev != null else 1)
	GameState.seen_events[event["id"]] = {"count": count, "day": GameState.day}
	var outcome: Dictionary = choice
	if choice.has("outcomes"):
		outcome = RNG.pick_weighted(choice["outcomes"])
	var changes := apply_effects(outcome.get("effects", {}))
	var text: String = outcome.get("result", "")
	GameState.add_log("Day %d. %s: %s" % [GameState.day, event["title"], choice["text"]])
	if text != "":
		GameState.add_log("   " + text)
	GameState.check_end_conditions()
	GameState.changed.emit()
	return {"text": text, "changes": changes}


## Applies effects and returns notes for the UI: [{"kind", "text", "good"}].
func apply_effects(fx: Dictionary) -> Array:
	var notes: Array = []
	for key in fx:
		var v: Variant = fx[key]
		if key in GameState.RESOURCE_KEYS:
			GameState.add_resource(key, float(v))
			notes.append(_note(key, "%s %s" % [_signed(v), GameState.RESOURCE_NAMES[key]], float(v) >= 0.0))
			continue
		match key:
			"colonists":
				GameState.colonists = maxi(0, GameState.colonists + int(v))
				notes.append(_note("colonists", "%s Colonists" % _signed(v), int(v) >= 0))
			"crew_health":
				for c in GameState.living_crew():
					c["health"] = clampf(float(c["health"]) + float(v), 0.0, 100.0)
				notes.append(_note("crew", "%s health, all crew" % _signed(v), float(v) >= 0.0))
			"crew_morale":
				for c in GameState.living_crew():
					c["morale"] = clampf(float(c["morale"]) + float(v), 0.0, 100.0)
				notes.append(_note("crew", "%s morale, all crew" % _signed(v), float(v) >= 0.0))
			"injure_random":
				var hurt := GameState.random_living_crew()
				if not hurt.is_empty():
					hurt["health"] = float(hurt["health"]) - float(v)
					notes.append(_note("crew", "%s injured (-%d health)" % [hurt["name"], int(v)], false))
			"kill_random":
				var victim := GameState.random_living_crew()
				if not victim.is_empty():
					victim["health"] = 0.0
					notes.append(_note("crew", "%s is lost" % victim["name"], false))
			"set_flag":
				GameState.flags[str(v)] = true
			"add_crew":
				GameState.add_crew_member(v.get("name", "Stranger"), v.get("role", "Crew"), v.get("trait", "Newcomer"))
				notes.append(_note("crew", "%s joins the crew" % v.get("name", "Stranger"), true))
			"days":
				TravelSim.idle_days(int(v))
				notes.append(_note("time", "%s lost" % GameState.days(int(v)), false))
			_:
				push_warning("Unknown event effect: %s" % key)
	return notes


func _note(kind: String, text: String, good: bool) -> Dictionary:
	return {"kind": kind, "text": text, "good": good}


func _signed(v: Variant) -> String:
	var n := int(v)
	return ("+" if n >= 0 else "") + str(n)


func _sector_ok(e: Dictionary, sector: int) -> bool:
	if not e.has("sector"):
		return true
	for s in e["sector"]:
		if int(s) == sector:
			return true
	return false


func _requirements_met(req: Dictionary) -> bool:
	if req.has("role") and not GameState.has_role(req["role"]):
		return false
	if req.has("flag") and not GameState.flags.has(req["flag"]):
		return false
	if req.has("not_flag") and GameState.flags.has(req["not_flag"]):
		return false
	if req.has("resources"):
		for key in req["resources"]:
			if GameState.get_res(key) < float(req["resources"][key]):
				return false
	return true
