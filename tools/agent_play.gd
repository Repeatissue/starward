extends Node
## Text-mode harness so a person, script or AI agent can play STARWARD one command at a time.
## Each call loads the run from a JSON file, applies ONE command, prints the new state, saves.
##
##   godot --headless --path . res://tools/agent_play.tscn -- <save.json> <command> [args]
##
## Commands:
##   new <corporate|navy|smuggler> [seed]   start a run (at Luna, shop first)
##   status                                 print state
##   buy <item> [packs]   / sell <item> [packs]    items: fuel food oxygen power parts hull (stations only)
##   thrust <cruise|burn|overdrive>
##   rations <full|reduced|starvation>
##   go <n>                                 pick the next stop on the star map (when ROUTE OPTIONS show)
##   travel                                 fly until an event, an arrival, a warning or 30 days pass
##   choose <n>                             answer the pending event (1-based)

var _path := ""
var _pending := ""
var _log_seen := 0
var _out: PackedStringArray = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("usage: -- <save.json> <command> [args]")
		get_tree().quit(1)
		return
	_path = args[0]
	var cmd: String = args[1].to_lower()
	var rest: Array = args.slice(2)
	if cmd != "new" and not _load():
		print("No run found at %s. Start one with: new <corporate|navy|smuggler> [seed]" % _path)
		get_tree().quit(1)
		return
	_run(cmd, rest)
	_print_state()
	_save()
	print("\n".join(_out))
	get_tree().quit()


func _run(cmd: String, rest: Array) -> void:
	if GameState.ended and cmd != "new" and cmd != "status":
		_say("The run is over. Start a new one with: new <captain> [seed]")
		return
	match cmd:
		"new":
			var bg_id: String = rest[0] if rest.size() > 0 else "corporate"
			var bg := {}
			for b in Data.backgrounds:
				if b["id"] == bg_id:
					bg = b
			if bg.is_empty():
				_say("Unknown captain '%s'. Use corporate, navy or smuggler." % bg_id)
				return
			var run_seed: int = int(rest[1]) if rest.size() > 1 else RNG.new_seed()
			GameState.new_run(run_seed, bg)
			_pending = ""
			_log_seen = 0
		"status":
			pass
		"buy", "sell":
			_trade(cmd, rest)
		"thrust":
			if _pending != "":
				_say("Answer the event first (choose <n>).")
			elif rest.size() > 0 and GameState.THRUST.has(rest[0]):
				GameState.thrust = rest[0]
				_say("Thrust set to %s." % rest[0])
			else:
				_say("thrust must be cruise, burn or overdrive")
		"rations":
			if _pending != "":
				_say("Answer the event first (choose <n>).")
			elif rest.size() > 0 and GameState.RATIONS.has(rest[0]):
				GameState.rations = rest[0]
				_say("Rations set to %s." % rest[0])
			else:
				_say("rations must be full, reduced or starvation")
		"travel":
			if _pending != "":
				_say("Answer the event first (choose <n>).")
				return
			var result := TravelSim.travel()
			if result.get("type", "") == "event":
				_pending = result["event"]["id"]
			elif result.get("type", "") == "alert":
				_say("WARNING - travel paused: " + str(result["text"]))
			elif result.get("type", "") == "choose":
				_say("Choose your next stop first: go <n> (see ROUTE OPTIONS).")
		"go":
			if _pending != "":
				_say("Answer the event first (choose <n>).")
				return
			var options := GameState.route_options()
			var n: int = int(rest[0]) if rest.size() > 0 else 0
			if options.is_empty():
				_say("Your course is already set. Use travel.")
			elif n < 1 or n > options.size():
				_say("Pick a route from 1 to %d." % options.size())
			else:
				GameState.choose_route(options[n - 1]["id"])
				_say("Course set for %s." % options[n - 1]["name"])
		"choose":
			if _pending == "":
				_say("There is no event to answer.")
				return
			var ev := EventEngine.get_event(_pending)
			var n: int = int(rest[0]) if rest.size() > 0 else 0
			if n < 1 or n > ev["choices"].size():
				_say("Pick a number from 1 to %d." % ev["choices"].size())
				return
			var choice: Dictionary = ev["choices"][n - 1]
			if not EventEngine.is_choice_available(choice):
				_say("You can't pick that: you don't meet its requirement.")
				return
			var res := EventEngine.resolve_choice(ev, choice)
			_pending = ""
			var notes: Array = []
			for c in res["changes"]:
				notes.append(c["text"])
			_say("OUTCOME: %s %s" % [res["text"], ("[" + ", ".join(PackedStringArray(notes)) + "]") if not notes.is_empty() else ""])
		_:
			_say("Unknown command '%s'." % cmd)


func _trade(cmd: String, rest: Array) -> void:
	if _pending != "":
		_say("Answer the event first (choose <n>).")
		return
	if GameState.current_node()["type"] != "station" or GameState.progress > 0.0:
		_say("You can only trade while docked at a station.")
		return
	var item_id: String = rest[0] if rest.size() > 0 else ""
	var packs: int = maxi(1, int(rest[1])) if rest.size() > 1 else 1
	var item := {}
	for it in Data.items:
		if it["id"] == item_id:
			item = it
	if item.is_empty():
		_say("Unknown item. Use fuel, food, oxygen, power, parts or hull.")
		return
	var price := int(round(float(item["price"]) * GameState.price_multiplier()))
	var sell_price := int(float(item["price"]) * 0.5)
	var done := 0
	for i in packs:
		if cmd == "buy":
			if GameState.get_res("credits") < price:
				break
			if item["resource"] == "hull" and GameState.get_res("hull") >= 100.0:
				break
			GameState.add_resource("credits", -price)
			GameState.add_resource(item["resource"], float(item["amount"]))
		else:
			if item["resource"] == "hull" or GameState.get_res(item["resource"]) < float(item["amount"]):
				break
			GameState.add_resource(item["resource"], -float(item["amount"]))
			GameState.add_resource("credits", sell_price)
		done += 1
	_say("%s %d of %d pack(s) of %s at %d credits each." % ["Bought" if cmd == "buy" else "Sold", done, packs, item["name"], price if cmd == "buy" else sell_price])


func _say(text: String) -> void:
	_out.append(">> " + text)


func _print_state() -> void:
	var lines: Array = GameState.log_lines
	if _log_seen < lines.size():
		_out.append("\n--- LOG ---")
		for i in range(_log_seen, lines.size()):
			_out.append(str(lines[i]))
	_log_seen = lines.size()

	if GameState.ended:
		_out.append("\n=== %s ===" % ("LANDFALL: YOU WIN" if GameState.victory else "GAME OVER"))
		_out.append(GameState.end_reason)
		if GameState.victory:
			_out.append("Day %d. Colonists delivered %d/%d. Crew alive %d. Score %d." % [GameState.day, GameState.colonists,
				GameState.STARTING_COLONISTS, GameState.living_crew().size(), GameState.score()])
		else:
			_out.append("Day %d. Journey %d%% complete. %d colonists lost with the ship. Partial score %d." % [GameState.day,
				int(GameState.journey_fraction() * 100.0), GameState.colonists, GameState.score()])
		return

	var node := GameState.current_node()
	var stop := GameState.next_stop()
	_out.append("\n--- STATUS (Day %d) ---" % GameState.day)
	var where := "At: %s (%s, %s)." % [node["name"], node["type"], node["sector_name"]]
	if GameState.progress > 0.0:
		where = "In flight from %s toward %s." % [node["name"], GameState.next_node()["name"]]
	_out.append("%s  Next resupply: %s in ~%s at %s." % [where,
		stop["name"], GameState.days(ceili(float(stop["distance"]) / GameState.speed())), GameState.thrust])
	var use: Array = []
	for key in ["fuel", "food", "oxygen", "power"]:
		use.append("%s %.1f" % [key, GameState.daily_use(key)])
	_out.append("Daily use at current settings: " + ", ".join(PackedStringArray(use)))
	_out.append("Journey %d%% complete. Thrust %s, rations %s." % [int(100.0 * GameState.distance_travelled() / GameState.total_distance()), GameState.thrust, GameState.rations])
	var res: Array = []
	for key in GameState.RESOURCE_KEYS:
		var dl := ""
		if key in ["fuel", "food", "oxygen", "power"]:
			dl = " (~%s)" % GameState.days(int(GameState.days_left(key)))
		res.append("%s %d%s" % [key, int(GameState.get_res(key)), dl])
	_out.append("Ship: " + ", ".join(PackedStringArray(res)) + ", colonists %d" % GameState.colonists)
	for c in GameState.crew:
		if c["alive"]:
			var sick: String = c.get("sick", "")
			_out.append("  %s - %s (%s): health %d, morale %d%s" % [c["name"], c["role"], c["trait"], int(c["health"]), int(c["morale"]), (", SICK with " + sick) if sick != "" else ""])
		else:
			_out.append("  %s - %s: DEAD" % [c["name"], c["role"]])
	if node["type"] == "station" and _pending == "" and GameState.progress == 0.0:
		var prices: Array = []
		for it in Data.items:
			prices.append("%s %d" % [it["id"], int(round(float(it["price"]) * GameState.price_multiplier()))])
		_out.append("DOCKED - you can trade. Price per pack: " + ", ".join(PackedStringArray(prices)) + ". Pack sizes: 10 units (parts 1, hull +10).")
	if _pending != "":
		var ev := EventEngine.get_event(_pending)
		_out.append("\n*** EVENT: %s ***" % ev["title"])
		_out.append(str(ev["text"]))
		var n := 1
		for choice in ev["choices"]:
			var ok := EventEngine.is_choice_available(choice)
			_out.append("  %d. %s%s" % [n, EventEngine.choice_label(choice), "" if ok else "   (UNAVAILABLE)"])
			n += 1
		_out.append("Answer with: choose <n>")
	elif GameState.needs_route_choice():
		_out.append("\n*** ROUTE OPTIONS (choose with: go <n>) ***")
		var i := 1
		for opt in GameState.route_options():
			var d := ceili(float(opt["distance"]) / GameState.speed())
			var onward: Array = []
			for nid in opt.get("next", []):
				onward.append(str(GameState.map_node(nid).get("name", "?")))
			var extra := ""
			if opt["type"] == "station":
				extra = ", can trade (prices +%d%%)" % int(25 * int(opt["sector"]))
			_out.append("  %d. %s - %s, %s away%s. Leads on to: %s" % [i, opt["name"], str(opt["type"]).to_upper(), GameState.days(d), extra, ", ".join(PackedStringArray(onward))])
			i += 1
		_out.append("Hazards are shortcuts but dangerous; stations are detours where you can resupply.")
	else:
		_out.append("Next: travel (or change thrust/rations, or trade if docked).")


func _save() -> void:
	var d := GameState.to_dict()
	d["pending_event"] = _pending
	d["log_seen"] = _log_seen
	d["ended"] = GameState.ended
	d["victory"] = GameState.victory
	d["end_reason"] = GameState.end_reason
	var f := FileAccess.open(_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func _load() -> bool:
	if not FileAccess.file_exists(_path):
		return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path))
	if not (d is Dictionary):
		return false
	GameState.from_dict(d)
	_pending = str(d.get("pending_event", ""))
	_log_seen = int(d.get("log_seen", 0))
	if d.get("ended", false):
		GameState.ended = true
		GameState.victory = bool(d.get("victory", false))
		GameState.end_reason = str(d.get("end_reason", ""))
	return true
