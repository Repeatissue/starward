extends Node
## Picks events, checks choice requirements and applies outcomes.
## Event format: see data/events/*.json and the README.

const DAILY_EVENT_CHANCE := 0.18


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
	if e.get("once", true) and GameState.seen_events.has(e["id"]):
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
	return prefix + str(choice["text"]) + ("   (%s)" % hint if hint != "" else "")


## Applies the choice (or one of its weighted outcomes).
## Returns {"text": String, "changes": Array[String]} for the popup.
func resolve_choice(event: Dictionary, choice: Dictionary) -> Dictionary:
	GameState.seen_events[event["id"]] = true
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
				notes.append(_note("time", "%d days lost" % int(v), false))
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
