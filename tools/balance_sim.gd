extends Node
## Headless balance simulator + smoke test.
## Run:  godot --headless --path . res://tools/balance_sim.tscn
##
## Plays many seeded runs with two bots that shop the same way but choose differently:
##   random - picks any available event choice (a player who isn't thinking)
##   smart  - weighs each choice's expected effects against what the ship is short of
## If choices matter, the smart bot should win clearly more often than the random one.
## Then builds every UI screen once to catch runtime errors.

const RUNS_PER_BG := 200
const POLICIES := ["random", "smart"]

## Rough value of one unit of each effect, in credits, for the smart bot.
const VALUES := {
	"fuel": 2.5, "food": 1.5, "oxygen": 2.0, "power": 2.0, "hull": 7.0,
	"parts": 35.0, "credits": 0.7, "colonists": 12.0,
}


func _ready() -> void:
	print("=== STARWARD balance sim: %d runs per captain per bot ===" % RUNS_PER_BG)
	print("%-10s %-7s %6s %8s %10s %6s   top cause of loss" % ["captain", "bot", "win%", "days", "colonists", "crew"])
	for bg in Data.backgrounds:
		for policy in POLICIES:
			_simulate(bg, policy)
	_smoke_test_ui()  # quits when done


func _simulate(bg: Dictionary, policy: String) -> void:
	var wins := 0
	var days := 0
	var colonists := 0
	var survivors := 0
	var causes := {}
	for i in RUNS_PER_BG:
		GameState.new_run(1000 + i, bg)
		_shop()
		var guard := 0
		while not GameState.ended and guard < 500:
			guard += 1
			_set_rations()
			var result := TravelSim.travel()
			if result.get("type", "") == "choose":
				_pick_route(policy)
			elif result.get("type", "") == "event":
				_pick_choice(result["event"], policy)
			elif result.get("type", "") == "arrived" and GameState.current_node()["type"] == "station":
				_shop()
		if GameState.victory:
			wins += 1
			days += GameState.day
			colonists += GameState.colonists
			survivors += GameState.living_crew().size()
		else:
			var cause := _cause(GameState.end_reason) if GameState.ended else "stuck"
			causes[cause] = causes.get(cause, 0) + 1
	var top := ""
	var top_n := 0
	for c in causes:
		if causes[c] > top_n:
			top_n = causes[c]
			top = "%s (%d)" % [c, top_n]
	print("%-10s %-7s %5.0f%% %8.1f %10.1f %6.1f   %s" % [bg["id"], policy, 100.0 * wins / RUNS_PER_BG,
		float(days) / maxi(wins, 1), float(colonists) / maxi(wins, 1), float(survivors) / maxi(wins, 1), top])


func _cause(reason: String) -> String:
	if "crew is gone" in reason:
		return "crew died"
	if "hull" in reason:
		return "hull destroyed"
	if "cryo pod" in reason:
		return "colonists died"
	return reason.substr(0, 30)


## Both bots shop the same way: cover the remaining trip plus a margin, then spare parts.
func _shop() -> void:
	var markup := GameState.price_multiplier()
	var remaining := GameState.total_distance() - GameState.distance_travelled()
	var targets := {}
	for key in ["fuel", "food", "oxygen", "power"]:
		targets[key] = GameState.supply_needed(key, remaining) * 1.15
	targets["parts"] = 2.0
	targets["hull"] = 70.0
	var bought := true
	while bought:
		bought = false
		for item in Data.items:
			var res_key: String = item["resource"]
			if not targets.has(res_key) or GameState.get_res(res_key) >= targets[res_key]:
				continue
			var cost := float(item["price"]) * markup
			if GameState.get_res("credits") >= cost:
				GameState.add_resource("credits", -cost)
				GameState.add_resource(res_key, float(item["amount"]))
				bought = true


## Both bots ration sensibly: cut rations when food won't reach the next stop.
func _set_rations() -> void:
	var stop := GameState.next_stop()
	var days_needed := float(stop["distance"]) / GameState.speed()
	GameState.rations = "full"
	if GameState.days_left("food") < days_needed:
		GameState.rations = "reduced"
		if GameState.days_left("food") < days_needed:
			GameState.rations = "starvation"


## random: any route. smart: shortest overall path, but heads for a station when supplies or
## hull won't comfortably last, and avoids hazards when the hull is weak.
func _pick_route(policy: String) -> void:
	var options := GameState.route_options()
	var pick: Dictionary = RNG.pick(options)
	if policy == "smart":
		var best := -INF
		for opt in options:
			var days := float(opt["distance"]) / GameState.speed()
			var score := -(float(opt["distance"]) + GameState.remaining_from(opt["id"])) * 10.0
			var needy := false
			for key in ["fuel", "food", "oxygen", "power"]:
				if GameState.days_left(key) - days < 8.0:
					needy = true
			if opt["type"] == "station" and (needy or GameState.get_res("hull") < 60.0) and GameState.get_res("credits") > 60.0:
				score += 120.0
			if opt["type"] == "hazard" and GameState.get_res("hull") < 50.0:
				score -= 80.0
			if opt["type"] == "derelict":
				score += 15.0
			if score > best:
				best = score
				pick = opt
	GameState.choose_route(pick["id"])


func _pick_choice(ev: Dictionary, policy: String) -> void:
	var options: Array = []
	for choice in ev["choices"]:
		if EventEngine.is_choice_available(choice):
			options.append(choice)
	if options.is_empty():
		push_error("Event %s has no available choice!" % ev["id"])
		return
	var pick: Dictionary = RNG.pick(options)
	if policy == "smart":
		var best := -INF
		for choice in options:
			var v := _value_of_choice(choice)
			if v > best:
				best = v
				pick = choice
	EventEngine.resolve_choice(ev, pick)


func _value_of_choice(choice: Dictionary) -> float:
	if not choice.has("outcomes"):
		return _value_of_effects(choice.get("effects", {}))
	var total := 0.0
	var weight := 0.0
	for o in choice["outcomes"]:
		var w := float(o.get("weight", 1.0))
		total += w * _value_of_effects(o.get("effects", {}))
		weight += w
	return total / maxf(weight, 1.0)


func _value_of_effects(fx: Dictionary) -> float:
	var living := GameState.living_crew().size()
	var stop_days := float(GameState.next_stop()["distance"]) / GameState.speed()
	var v := 0.0
	for key in fx:
		var amount: Variant = fx[key]
		if VALUES.has(key):
			var unit: float = VALUES[key]
			# Things we're about to run out of are worth much more.
			if key in ["fuel", "food", "oxygen", "power"] and GameState.days_left(key) < stop_days + 3.0:
				unit *= 4.0
			if key == "hull" and GameState.get_res("hull") < 50.0:
				unit *= 3.0
			if key == "credits" and float(amount) < 0.0 and GameState.get_res("credits") + float(amount) < 0.0:
				unit *= 3.0
			v += float(amount) * unit
		else:
			match key:
				"crew_health": v += float(amount) * living * 4.0
				"crew_morale": v += float(amount) * living * 1.5
				"injure_random": v -= float(amount) * 5.0
				"kill_random": v -= 500.0
				"add_crew": v += 120.0
				"days": v -= float(amount) * 22.0
	return v


func _smoke_test_ui() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	GameState.new_run(42, Data.backgrounds[0])
	for screen in ["menu", "new_run", "outfitter", "travel"]:
		main.goto(screen, {"mode": "departure"})
		await get_tree().process_frame
	var chooser := RouteChooser.new()
	chooser.setup(func(): pass, func(): pass)
	main.current.add_child(chooser)
	await get_tree().process_frame
	chooser.queue_free()
	var popup := EventPopup.new()
	popup.setup(Data.events[0], func(): pass)
	main.current.add_child(popup)
	await get_tree().process_frame
	GameState.end_run(true, "Smoke test arrival.")
	main.goto("report")
	await get_tree().process_frame
	print("UI smoke test: all screens built.")
	get_tree().quit()
