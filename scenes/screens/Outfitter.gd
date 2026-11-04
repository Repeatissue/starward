extends BaseScreen
## Buy and sell supplies. "departure" mode = Luna prices; "station" mode = 50% markup.

const STATION_MARKUP := 1.5
const SELL_RATE := 0.5

var _price_mult := 1.0
var _credits_label: Label
var _rows: Dictionary = {}


func build() -> void:
	var departure: bool = params.get("mode", "departure") == "departure"
	_price_mult = 1.0 if departure else STATION_MARKUP

	var root := make_root()
	root.add_child(UIKit.label("Outfitter: %s" % GameState.current_node()["name"], 40, UIKit.ACCENT))
	if departure:
		root.add_child(UIKit.para(
			"Stock up before launch. Earth 2 is about %d light-units away. At Cruise you cover 1 light-unit per day on 2 fuel. Your crew of %d eats %d food and breathes %.1f oxygen a day, and the cryo bay draws 1 power a day." % [
				int(GameState.total_distance()), GameState.living_crew().size(), GameState.living_crew().size(),
				GameState.living_crew().size() * TravelSim.O2_PER_CREW], 20, UIKit.DIM))
	else:
		root.add_child(UIKit.para("Prices out here are 50% higher than at home. Sell what you can spare.", 20, UIKit.DIM))

	_credits_label = UIKit.label("", 28, UIKit.ACCENT)
	root.add_child(_credits_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var list := UIKit.vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for item in Data.items:
		var row := UIKit.hbox(12)
		var name_label := UIKit.label(item["name"], 22)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var have := UIKit.label("", 22, UIKit.DIM)
		have.custom_minimum_size = Vector2(150, 0)
		row.add_child(have)
		var buy := UIKit.button("Buy %d cr" % _price(item), func(): _buy(item), 170)
		row.add_child(buy)
		var sell := UIKit.button("Sell %d cr" % _sell_price(item), func(): _sell(item), 170)
		row.add_child(sell)
		list.add_child(row)
		_rows[item["id"]] = {"have": have, "buy": buy, "sell": sell}

	var bottom := UIKit.hbox()
	bottom.add_child(UIKit.filler())
	bottom.add_child(UIKit.button("Launch" if departure else "Undock", _leave, 220))
	root.add_child(bottom)
	_refresh()


func _price(item: Dictionary) -> int:
	return int(round(float(item["price"]) * _price_mult))


func _sell_price(item: Dictionary) -> int:
	return int(float(item["price"]) * SELL_RATE)


func _buy(item: Dictionary) -> void:
	var cost := _price(item)
	if GameState.get_res("credits") < cost:
		return
	GameState.add_resource("credits", -cost)
	GameState.add_resource(item["resource"], float(item["amount"]))
	_refresh()


func _sell(item: Dictionary) -> void:
	if GameState.get_res(item["resource"]) < float(item["amount"]):
		return
	GameState.add_resource(item["resource"], -float(item["amount"]))
	GameState.add_resource("credits", _sell_price(item))
	_refresh()


func _refresh() -> void:
	var credits := GameState.get_res("credits")
	_credits_label.text = "Credits: %d" % int(credits)
	for item in Data.items:
		var row: Dictionary = _rows[item["id"]]
		var res_key: String = item["resource"]
		var have_amount := GameState.get_res(res_key)
		(row["have"] as Label).text = "Have: %d" % int(have_amount)
		var at_cap: bool = GameState.RESOURCE_CAPS.has(res_key) and have_amount >= float(GameState.RESOURCE_CAPS[res_key])
		(row["buy"] as Button).disabled = credits < _price(item) or at_cap
		# Hull plating can't be sold back.
		(row["sell"] as Button).disabled = res_key == "hull" or have_amount < float(item["amount"])


func _leave() -> void:
	SaveManager.save_game()
	goto("travel")
