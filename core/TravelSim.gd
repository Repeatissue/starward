extends Node
## The daily simulation: movement, supply drain, crew health and arrivals.

const O2_PER_CREW := 0.5
const CRYO_POWER_PER_DAY := 1.0
const DRIFT_SPEED := 0.25
const MAX_DAYS_PER_PRESS := 30

# --- Difficulty knobs (tune with tools/balance_sim) -----------------------
## Morale slowly wears down on a long voyage, whatever the rations.
const MORALE_DRIFT := -0.4
## Daily chance per crew member of falling ill, plus extra risk from hard living.
const ILLNESS_BASE := 0.015
const ILLNESS_BY_RATIONS := {"full": 0.0, "reduced": 0.006, "starvation": 0.02}
const ILLNESS_BY_THRUST := {"cruise": 0.0, "burn": 0.004, "overdrive": 0.01}
const ILLNESS_LOW_MORALE := 0.008
const ILLNESS_LOW_HEALTH := 0.006
## Health lost per day while ill (halved with a Medic), and daily recovery chance.
const ILLNESS_DAMAGE := 5.5
const RECOVERY_BASE := 0.08
const RECOVERY_MEDIC := 0.12
const RECOVERY_FULL_RATIONS := 0.05
## Daily chance a ship system breaks and needs a spare part.
const BREAKDOWN_BASE := 0.02
const BREAKDOWN_BY_THRUST := {"cruise": 0.0, "burn": 0.01, "overdrive": 0.03}

const ILLNESSES := ["radiation sickness", "void fever", "bone-loss syndrome", "station flu", "a broken arm", "infected burns", "decompression sickness"]
const SYSTEMS := ["main thruster coupling", "reactor coolant pump", "navigation computer", "hull pressure seal", "cryo bay regulator", "water reclaimer", "airlock motor"]

var _warned: Dictionary = {}
var _repairing := false


## Advances day by day until something needs the player.
## Returns {"type": "event", "event": {...}}, {"type": "arrived"}, {"type": "ended"} or {"type": "pause"}.
func travel() -> Dictionary:
	if GameState.ended or GameState.next_node().is_empty():
		return {"type": "ended"}
	for i in MAX_DAYS_PER_PRESS:
		_tick_day(true)
		if GameState.ended:
			return {"type": "ended"}
		var nxt := GameState.next_node()
		if GameState.progress >= float(nxt["distance"]):
			return _arrive()
		var ev := EventEngine.roll_travel_event()
		if not ev.is_empty():
			return {"type": "event", "event": ev}
	return {"type": "pause"}


## Days spent waiting (storms, detours): supplies drain but the ship doesn't move.
func idle_days(count: int) -> void:
	for i in count:
		if GameState.ended:
			return
		_tick_day(false)


func _tick_day(moving: bool) -> void:
	GameState.day += 1
	var t: Dictionary = GameState.THRUST[GameState.thrust]
	var r: Dictionary = GameState.RATIONS[GameState.rations]
	var living: Array = GameState.living_crew()

	# Movement and fuel.
	if moving:
		var fuel_need := float(t["fuel"])
		if GameState.get_res("fuel") >= fuel_need:
			GameState.add_resource("fuel", -fuel_need)
			GameState.progress += float(t["speed"])
			GameState.add_resource("hull", -float(t["hull"]))
			_clear_warning("no_fuel")
		else:
			GameState.add_resource("fuel", -GameState.get_res("fuel"))
			GameState.progress += DRIFT_SPEED
			_warn("no_fuel", "Out of fuel. The ship coasts forward at a crawl.")

	# Food.
	var food_need := GameState.daily_use("food")
	var fed := GameState.get_res("food") >= food_need
	GameState.add_resource("food", -food_need)
	if fed:
		_clear_warning("no_food")
	else:
		_warn("no_food", "The food stores are empty. The crew is starving.")

	# Oxygen, plus leaks from a damaged hull.
	var o2_need := GameState.daily_use("oxygen")
	var breathing := GameState.get_res("oxygen") >= o2_need
	GameState.add_resource("oxygen", -o2_need)
	if breathing:
		_clear_warning("no_o2")
	else:
		_warn("no_o2", "Oxygen is gone. Every breath is thin and painful.")

	# Power keeps the cryo pods cold.
	if GameState.get_res("power") >= CRYO_POWER_PER_DAY:
		GameState.add_resource("power", -CRYO_POWER_PER_DAY)
		_clear_warning("no_power")
	else:
		GameState.add_resource("power", -GameState.get_res("power"))
		var lost := maxi(1, int(GameState.colonists * 0.03))
		GameState.colonists = maxi(0, GameState.colonists - lost)
		_warn("no_power", "No power for the cryo bay. Pods are failing.")
		GameState.add_log("Day %d. %d colonists died in their pods." % [GameState.day, lost])

	# Crew health and morale.
	for c in living:
		var dh := float(r["health"])
		var dm := float(r["morale"]) + float(t["morale"]) + MORALE_DRIFT
		if not fed:
			dh -= 8.0
			dm -= 5.0
		if not breathing:
			dh -= 20.0
		c["health"] = clampf(float(c["health"]) + dh, 0.0, 100.0)
		c["morale"] = clampf(float(c["morale"]) + dm, 0.0, 100.0)
		if float(c["morale"]) < 15.0 and RNG.chance(0.05):
			c["health"] = float(c["health"]) - 10.0
			GameState.add_log("Day %d. %s has a breakdown and hurts themself." % [GameState.day, c["name"]])

	_roll_illness()
	if not _repairing:
		_roll_breakdown()
	GameState.check_end_conditions()


## Like dysentery on the old trail, illness is the steady killer out here.
## Risk rises with poor rations, hard thrust, low morale and poor health. A Medic helps a lot.
func _roll_illness() -> void:
	var medic := GameState.has_role("Medic")
	for c in GameState.living_crew():
		var sick: String = c.get("sick", "")
		if sick != "":
			c["health"] = float(c["health"]) - (ILLNESS_DAMAGE * 0.5 if medic else ILLNESS_DAMAGE)
			var recover := RECOVERY_BASE + (RECOVERY_MEDIC if medic else 0.0) + (RECOVERY_FULL_RATIONS if GameState.rations == "full" else 0.0)
			if RNG.chance(recover):
				c["sick"] = ""
				GameState.add_log("Day %d. %s has recovered from %s." % [GameState.day, c["name"], sick])
			continue
		var p := ILLNESS_BASE + float(ILLNESS_BY_RATIONS[GameState.rations]) + float(ILLNESS_BY_THRUST[GameState.thrust])
		if float(c["morale"]) < 30.0:
			p += ILLNESS_LOW_MORALE
		if float(c["health"]) < 50.0:
			p += ILLNESS_LOW_HEALTH
		if RNG.chance(p):
			c["sick"] = RNG.pick(ILLNESSES)
			GameState.add_log("Day %d. %s has %s." % [GameState.day, c["name"], c["sick"]])


## Like a broken wagon axle: something fails, and you'd better have a spare part.
func _roll_breakdown() -> void:
	if not RNG.chance(BREAKDOWN_BASE + float(BREAKDOWN_BY_THRUST[GameState.thrust])):
		return
	var system: String = RNG.pick(SYSTEMS)
	var engineer := GameState.has_role("Engineer")
	_repairing = true
	if GameState.get_res("parts") >= 1.0 and engineer:
		GameState.add_resource("parts", -1.0)
		GameState.add_log("Day %d. The %s failed. Your engineer replaced it with a spare part." % [GameState.day, system])
	elif GameState.get_res("parts") >= 1.0:
		GameState.add_resource("parts", -1.0)
		GameState.add_log("Day %d. The %s failed. With no engineer, fitting the spare takes 2 days." % [GameState.day, system])
		idle_days(2)
	else:
		var lost := 3 if engineer else 6
		GameState.add_resource("hull", -5.0)
		GameState.add_log("Day %d. The %s failed and there are no spare parts. You lose %d days jury-rigging a fix." % [GameState.day, system, lost])
		idle_days(lost)
	_repairing = false


func _arrive() -> Dictionary:
	var previous_sector := int(GameState.current_node().get("sector", 1))
	GameState.node_index += 1
	GameState.progress = 0.0
	var node := GameState.current_node()
	if int(node["sector"]) != previous_sector:
		GameState.add_log("--- Entering %s ---" % node["sector_name"])
	GameState.add_log("Day %d. Arrived at %s." % [GameState.day, node["name"]])
	if node.has("description"):
		GameState.add_log("   " + str(node["description"]))

	if node["type"] == "destination":
		GameState.end_run(true, "Day %d. The %s settles into orbit above Earth 2. %d colonists wake to a new sky." % [
			GameState.day, GameState.SHIP_NAME, GameState.colonists])
		return {"type": "ended"}

	SaveManager.save_game()
	if node.has("event"):
		var ev := EventEngine.get_event(node["event"])
		if not ev.is_empty() and EventEngine.event_available(ev):
			return {"type": "event", "event": ev}
	return {"type": "arrived"}


func _warn(id: String, text: String) -> void:
	if not _warned.get(id, false):
		_warned[id] = true
		GameState.add_log("Day %d. %s" % [GameState.day, text])


func _clear_warning(id: String) -> void:
	_warned.erase(id)
