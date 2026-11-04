extends Node
## All state for the current run. Pure data and small helpers: no UI code here.

signal changed

const SAVE_VERSION := 1
const SHIP_NAME := "ISV Wayfarer"
const STARTING_COLONISTS := 200

const RESOURCE_KEYS := ["fuel", "food", "oxygen", "power", "hull", "parts", "credits"]
const RESOURCE_NAMES := {
	"fuel": "Fuel",
	"food": "Food",
	"oxygen": "Oxygen",
	"power": "Power",
	"hull": "Hull",
	"parts": "Spare Parts",
	"credits": "Credits",
}
const RESOURCE_CAPS := {"hull": 100.0}
const BASE_RESOURCES := {
	"fuel": 0.0, "food": 0.0, "oxygen": 40.0, "power": 50.0,
	"hull": 100.0, "parts": 0.0, "credits": 0.0,
}

const ROLES := ["Pilot", "Engineer", "Medic", "Scientist", "Security"]
const CREW_NAMES := [
	"Ada Reyes", "Tomas Vek", "Priya Nair", "Jonah Bell", "Sana Holt", "Ilya Moreau",
	"Kemi Adeyemi", "Rafe Calder", "Mei Tanaka", "Oskar Lind", "Nadia Farouk", "Eli Brandt",
]
const TRAITS := ["Brave", "Optimist", "Veteran", "Gambler", "Claustrophobic", "Stoic", "Hothead", "Dreamer"]

## Travel speed (light-units per day) versus fuel use and wear.
const THRUST := {
	"cruise": {"name": "Cruise", "speed": 1.0, "fuel": 2.0, "hull": 0.0, "morale": 0.0},
	"burn": {"name": "Burn", "speed": 1.5, "fuel": 4.0, "hull": 0.0, "morale": -0.5},
	"overdrive": {"name": "Overdrive", "speed": 2.0, "fuel": 7.0, "hull": 1.0, "morale": -1.5},
}
## Food per crew member per day, and the daily effect on health and morale.
const RATIONS := {
	"full": {"name": "Full", "food": 1.0, "health": 0.5, "morale": 0.5},
	"reduced": {"name": "Reduced", "food": 0.6, "health": 0.0, "morale": -1.0},
	"starvation": {"name": "Starvation", "food": 0.25, "health": -3.0, "morale": -3.0},
}

var run_seed: int = 0
var background: Dictionary = {}
var day: int = 0
var resources: Dictionary = {}
var colonists: int = 0
var crew: Array = []
var route: Array = []
var node_index: int = 0
var progress: float = 0.0
var thrust: String = "cruise"
var rations: String = "full"
var flags: Dictionary = {}
var seen_events: Dictionary = {}
var log_lines: Array = []
var run_active: bool = false
var ended: bool = false
var victory: bool = false
var end_reason: String = ""


func new_run(p_seed: int, bg: Dictionary) -> void:
	run_seed = p_seed
	RNG.set_seed(p_seed)
	background = bg
	day = 1
	resources = BASE_RESOURCES.duplicate()
	resources["credits"] = float(bg.get("credits", 1000))
	var bonus: Dictionary = bg.get("bonus", {})
	for key in bonus:
		add_resource(key, float(bonus[key]))
	colonists = STARTING_COLONISTS
	crew = []
	var names: Array = CREW_NAMES.duplicate()
	for role in ROLES:
		var name_text: String = names.pop_at(RNG.range_i(0, names.size() - 1))
		var trait_text: String = RNG.pick(TRAITS)
		crew.append(_make_crew(name_text, role, trait_text, 70.0))
	route = Data.build_route()
	node_index = 0
	progress = 0.0
	thrust = "cruise"
	rations = "full"
	flags = {}
	seen_events = {}
	log_lines = []
	run_active = true
	ended = false
	victory = false
	end_reason = ""
	add_log("Day 1. The %s waits at %s with %d colonists asleep in the hold. Seed %d." % [
		SHIP_NAME, current_node()["name"], colonists, run_seed])
	changed.emit()


func _make_crew(name_text: String, role: String, trait_text: String, morale: float) -> Dictionary:
	return {"name": name_text, "role": role, "trait": trait_text,
		"health": 100.0, "morale": morale, "alive": true, "sick": ""}


func add_crew_member(name_text: String, role: String, trait_text: String) -> void:
	crew.append(_make_crew(name_text, role, trait_text, 60.0))


# --- Route ---------------------------------------------------------------

func current_node() -> Dictionary:
	if route.is_empty():
		return {}
	return route[node_index]


func next_node() -> Dictionary:
	if node_index + 1 < route.size():
		return route[node_index + 1]
	return {}


func current_sector() -> int:
	var nxt := next_node()
	if not nxt.is_empty():
		return int(nxt.get("sector", 1))
	return int(current_node().get("sector", 1))


func total_distance() -> float:
	var total := 0.0
	for n in route:
		total += float(n.get("distance", 0.0))
	return total


func distance_travelled() -> float:
	var total := progress
	for i in range(1, node_index + 1):
		total += float(route[i].get("distance", 0.0))
	return total


## The next stop where you can resupply (a station or Earth 2), and how far away it is.
func next_stop() -> Dictionary:
	var dist := -progress
	for i in range(node_index + 1, route.size()):
		dist += float(route[i].get("distance", 0.0))
		if route[i]["type"] in ["station", "destination"]:
			return {"name": route[i]["name"], "distance": maxf(dist, 0.0)}
	return {"name": "Earth 2", "distance": maxf(dist, 0.0)}


# --- Supplies forecast ---------------------------------------------------

## Prices climb the further you get from home, as they did at the old trail's forts.
func price_multiplier() -> float:
	if node_index == 0:
		return 1.0
	return 1.0 + 0.25 * int(current_node().get("sector", 1))


func speed() -> float:
	return float(THRUST[thrust]["speed"])


## How much of a resource the ship uses per day at the current settings.
func daily_use(key: String) -> float:
	var n := living_crew().size()
	match key:
		"food":
			return n * float(RATIONS[rations]["food"])
		"oxygen":
			return n * TravelSim.O2_PER_CREW + maxf(0.0, (50.0 - get_res("hull")) * 0.04)
		"power":
			return TravelSim.CRYO_POWER_PER_DAY
		"fuel":
			return float(THRUST[thrust]["fuel"])
	return 0.0


func days_left(key: String) -> float:
	var use := daily_use(key)
	if use <= 0.0:
		return 9999.0
	return get_res(key) / use


## Roughly how much of a resource covering `distance` light-units will take at current settings.
func supply_needed(key: String, distance: float) -> float:
	return ceilf(daily_use(key) * distance / speed())


# --- Resources & crew ----------------------------------------------------

func get_res(key: String) -> float:
	return float(resources.get(key, 0.0))


func add_resource(key: String, amount: float) -> void:
	var cap: float = RESOURCE_CAPS.get(key, 9999.0)
	resources[key] = clampf(get_res(key) + amount, 0.0, cap)


func living_crew() -> Array:
	return crew.filter(func(c): return c["alive"])


func has_role(role: String) -> bool:
	for c in living_crew():
		if c["role"] == role:
			return true
	return false


func random_living_crew() -> Dictionary:
	var living := living_crew()
	if living.is_empty():
		return {}
	return RNG.pick(living)


# --- Log & end state -----------------------------------------------------

func add_log(text: String) -> void:
	log_lines.append(text)


func check_end_conditions() -> void:
	if ended:
		return
	for c in crew:
		if c["alive"] and float(c["health"]) <= 0.0:
			c["alive"] = false
			c["health"] = 0.0
			add_log("%s, your %s, has died. You commit them to the dark." % [c["name"], c["role"]])
	if living_crew().is_empty():
		end_run(false, "The last of your crew is gone. The %s drifts on, silent, its sleepers never to wake." % SHIP_NAME)
	elif get_res("hull") <= 0.0:
		end_run(false, "The hull gives way. The %s breaks apart between the stars." % SHIP_NAME)
	elif colonists <= 0:
		end_run(false, "The last cryo pod has failed. There is no one left to deliver.")


func end_run(win: bool, reason: String) -> void:
	ended = true
	victory = win
	end_reason = reason
	run_active = false
	add_log(reason)
	changed.emit()


func score() -> int:
	if not victory:
		return 0
	var base := colonists * 10 + living_crew().size() * 200 + int(get_res("hull")) * 2 + int(get_res("credits") / 10.0)
	return int(base * float(background.get("score_mult", 1.0)))


# --- Save data -----------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"run_seed": str(run_seed),
		"rng_state": RNG.get_state(),
		"background": background,
		"day": day,
		"resources": resources,
		"colonists": colonists,
		"crew": crew,
		"route": route,
		"node_index": node_index,
		"progress": progress,
		"thrust": thrust,
		"rations": rations,
		"flags": flags,
		"seen_events": seen_events,
		"log_lines": log_lines,
	}


func from_dict(d: Dictionary) -> void:
	run_seed = str(d.get("run_seed", "0")).to_int()
	RNG.set_state(str(d.get("rng_state", "0")))
	background = d.get("background", {})
	day = int(d.get("day", 1))
	resources = d.get("resources", BASE_RESOURCES.duplicate())
	colonists = int(d.get("colonists", 0))
	crew = d.get("crew", [])
	route = d.get("route", [])
	node_index = int(d.get("node_index", 0))
	progress = float(d.get("progress", 0.0))
	thrust = str(d.get("thrust", "cruise"))
	rations = str(d.get("rations", "full"))
	flags = d.get("flags", {})
	seen_events = d.get("seen_events", {})
	log_lines = d.get("log_lines", [])
	run_active = true
	ended = false
	victory = false
	end_reason = ""
	changed.emit()
