extends Node
## Headless balance simulator + smoke test.
## Run:  godot --headless --path . res://tools/balance_sim.tscn
## Auto-plays many seeded runs with a simple bot, prints win rate and causes of death,
## then builds every UI screen once to catch runtime errors.

const RUNS := 300
const SHOPPING_TARGETS := {"fuel": 110.0, "food": 230.0, "oxygen": 120.0, "power": 70.0, "parts": 2.0}


func _ready() -> void:
	var wins := 0
	var by_bg := {}
	var causes := {}
	var total_days := 0
	var total_colonists := 0
	for i in RUNS:
		var bg: Dictionary = Data.backgrounds[i % Data.backgrounds.size()]
		GameState.new_run(1000 + i, bg)
		_shop()
		var guard := 0
		while not GameState.ended and guard < 500:
			guard += 1
			var result := TravelSim.travel()
			if result.get("type", "") == "event":
				_pick_choice(result["event"])
			elif result.get("type", "") == "arrived" and GameState.current_node()["type"] == "station":
				_shop()
		var key: String = bg["id"]
		if not by_bg.has(key):
			by_bg[key] = [0, 0]
		by_bg[key][1] += 1
		if GameState.victory:
			wins += 1
			by_bg[key][0] += 1
			total_days += GameState.day
			total_colonists += GameState.colonists
		else:
			var cause := GameState.end_reason.substr(0, 40) if GameState.ended else "stuck (guard hit)"
			causes[cause] = causes.get(cause, 0) + 1

	print("=== STARWARD balance sim: %d runs ===" % RUNS)
	print("Win rate: %.1f%%" % (100.0 * wins / RUNS))
	for key in by_bg:
		print("  %-10s %d / %d" % [key, by_bg[key][0], by_bg[key][1]])
	if wins > 0:
		print("Avg days on win: %.1f   Avg colonists on win: %.1f" % [float(total_days) / wins, float(total_colonists) / wins])
	print("Losses by cause:")
	for c in causes:
		print("  %3d  %s..." % [causes[c], c])

	_smoke_test_ui()  # quits when done


## Bot shopping: spread credits across supplies until targets are met.
func _shop() -> void:
	var markup := 1.0 if GameState.node_index == 0 else 1.5
	var bought := true
	while bought:
		bought = false
		for item in Data.items:
			var res_key: String = item["resource"]
			if not SHOPPING_TARGETS.has(res_key) or GameState.get_res(res_key) >= SHOPPING_TARGETS[res_key]:
				continue
			var cost := float(item["price"]) * markup
			if GameState.get_res("credits") >= cost:
				GameState.add_resource("credits", -cost)
				GameState.add_resource(res_key, float(item["amount"]))
				bought = true


## Bot choice: a random available choice.
func _pick_choice(ev: Dictionary) -> void:
	var options: Array = []
	for choice in ev["choices"]:
		if EventEngine.is_choice_available(choice):
			options.append(choice)
	if options.is_empty():
		push_error("Event %s has no available choice!" % ev["id"])
		return
	EventEngine.resolve_choice(ev, RNG.pick(options))


func _smoke_test_ui() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	GameState.new_run(42, Data.backgrounds[0])
	for screen in ["menu", "new_run", "outfitter", "travel"]:
		main.goto(screen, {"mode": "departure"})
		await get_tree().process_frame
	var popup := EventPopup.new()
	popup.setup(Data.events[0], func(): pass)
	main.current.add_child(popup)
	await get_tree().process_frame
	GameState.end_run(true, "Smoke test arrival.")
	main.goto("report")
	await get_tree().process_frame
	print("UI smoke test: all screens built.")
	get_tree().quit()
