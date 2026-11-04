extends Node
## Seeded random numbers for the whole run.
## Every gameplay roll goes through here so a seed always replays the same journey.

var _rng := RandomNumberGenerator.new()


func set_seed(value: int) -> void:
	_rng.seed = value


func new_seed() -> int:
	var r := RandomNumberGenerator.new()
	r.randomize()
	return r.randi()


## State is saved as a string because JSON would lose 64-bit precision.
func get_state() -> String:
	return str(_rng.state)


func set_state(value: String) -> void:
	_rng.state = value.to_int()


func roll() -> float:
	return _rng.randf()


func range_i(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


func range_f(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


func chance(probability: float) -> bool:
	return _rng.randf() < probability


func pick(items: Array) -> Variant:
	if items.is_empty():
		return null
	return items[range_i(0, items.size() - 1)]


## Picks from an array of Dictionaries using each one's `weight` (default 1).
func pick_weighted(items: Array, key: String = "weight") -> Variant:
	if items.is_empty():
		return null
	var total := 0.0
	for item in items:
		total += float(item.get(key, 1.0))
	var r := _rng.randf() * total
	for item in items:
		r -= float(item.get(key, 1.0))
		if r <= 0.0:
			return item
	return items.back()
