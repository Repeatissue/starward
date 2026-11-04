extends BaseScreen
## Buy and sell supplies. Each card shows what you have against what the trip needs.
## "departure" mode = Luna prices; "station" mode = 50% markup.

const STATION_MARKUP := 1.5
const SELL_RATE := 0.5
const CONSUMABLES := ["fuel", "food", "oxygen", "power"]

var _departure := true
var _price_mult := 1.0
var _distance := 0.0
var _credits_label: Label
var _cards: Dictionary = {}
var _summary: HBoxContainer


func build() -> void:
	_departure = params.get("mode", "departure") == "departure"
	_price_mult = 1.0 if _departure else STATION_MARKUP
	_distance = GameState.total_distance() - GameState.distance_travelled()

	var root := make_root(28, 12)
	var head := UIKit.hbox(16)
	head.add_child(IconView.new("station", 54))
	var hv := UIKit.vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(UIKit.title("OUTFITTER", 32, UIKit.ACCENT))
	hv.add_child(UIKit.label("%s  -  %s" % [GameState.current_node()["name"], "home prices" if _departure else "frontier prices (+50%)"], 17, UIKit.DIM))
	head.add_child(hv)
	var wallet := UIKit.panel("CardPanel")
	var wrow := UIKit.hbox(10)
	wrow.add_child(IconView.new("credits", 30))
	_credits_label = UIKit.title("", 26, UIKit.KIND_COLORS["credits"])
	wrow.add_child(_credits_label)
	wallet.add_child(wrow)
	head.add_child(wallet)
	root.add_child(head)

	var tip := UIKit.panel("AdvisorPanel")
	var trow := UIKit.hbox(12)
	trow.add_child(IconView.new("crew", 30, UIKit.ACCENT))
	var tip_text := "Earth 2 is %d light-units away. Each bar compares what you have with what the whole trip needs at %s speed on %s rations. Fill the bars to green, and keep some credits for emergencies." % [
		int(_distance), GameState.THRUST[GameState.thrust]["name"], GameState.RATIONS[GameState.rations]["name"]]
	if not _departure:
		tip_text = "%d light-units left to Earth 2. Bars show what you need to finish the trip at your current settings." % int(_distance)
	trow.add_child(UIKit.para(tip_text, 16))
	tip.add_child(trow)
	root.add_child(tip)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	root.add_child(grid)
	for item in Data.items:
		grid.add_child(_make_card(item))

	# Your ship waiting in the dock, engines cold.
	var ship := ShipView.new()
	ship.set_thrust("none")
	ship.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ship.custom_minimum_size = Vector2(0, 90)
	root.add_child(ship)

	var bottom := UIKit.hbox(10)
	bottom.add_child(UIKit.heading("SUPPLY CHECK"))
	_summary = UIKit.hbox(8)
	bottom.add_child(_summary)
	bottom.add_child(UIKit.filler())
	var go := UIKit.primary_button("LAUNCH  >" if _departure else "UNDOCK  >", _leave, 240)
	go.custom_minimum_size.y = 56
	bottom.add_child(go)
	root.add_child(bottom)
	_refresh()


func _make_card(item: Dictionary) -> Control:
	var res_key: String = item["resource"]
	var card := UIKit.panel("CardPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UIKit.vbox(6)
	card.add_child(v)
	var top := UIKit.hbox(10)
	top.add_child(IconView.new(res_key, 38))
	var tv := UIKit.vbox(0)
	tv.add_child(UIKit.label(item["name"], 19, Icons.color_for(res_key)))
	var have := UIKit.label("", 15, UIKit.TEXT)
	tv.add_child(have)
	top.add_child(tv)
	v.add_child(top)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	var fill := StyleBoxFlat.new()
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	v.add_child(bar)
	var need := UIKit.label("", 14, UIKit.DIM)
	v.add_child(need)
	var btns := UIKit.hbox(8)
	var buy := UIKit.primary_button("Buy  %d" % _price(item), func(): _buy(item))
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(buy)
	var sell := UIKit.button("Sell  %d" % _sell_price(item), func(): _sell(item))
	sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(sell)
	v.add_child(btns)
	_cards[item["id"]] = {"have": have, "bar": bar, "fill": fill, "need": need, "buy": buy, "sell": sell}
	return card


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
	_credits_label.text = str(int(credits))
	for child in _summary.get_children():
		_summary.remove_child(child)
		child.queue_free()
	for key in CONSUMABLES:
		var ok := GameState.get_res(key) >= GameState.supply_needed(key, _distance)
		_summary.add_child(UIKit.chip(("%s OK" if ok else "%s short") % GameState.RESOURCE_NAMES[key], UIKit.GOOD if ok else UIKit.BAD, key))
	for item in Data.items:
		var card: Dictionary = _cards[item["id"]]
		var res_key: String = item["resource"]
		var have := GameState.get_res(res_key)
		var bar: ProgressBar = card["bar"]
		var fill: StyleBoxFlat = card["fill"]
		var need_label: Label = card["need"]
		(card["have"] as Label).text = "You have %d" % int(have)
		if res_key in CONSUMABLES:
			var need := GameState.supply_needed(res_key, _distance)
			bar.max_value = maxf(need, 1.0)
			bar.value = have
			var enough := have >= need
			fill.bg_color = UIKit.GOOD if enough else UIKit.BAD
			need_label.text = ("Enough for the trip (needs ~%d)" if enough else "Short! The trip needs ~%d") % int(need)
			need_label.add_theme_color_override("font_color", UIKit.GOOD if enough else UIKit.BAD)
		elif res_key == "hull":
			bar.max_value = 100.0
			bar.value = have
			fill.bg_color = Icons.color_for("hull") if have >= 50.0 else UIKit.BAD
			need_label.text = "Below 50, the hull leaks oxygen"
		else:
			bar.max_value = 4.0
			bar.value = have
			fill.bg_color = Icons.color_for(res_key)
			need_label.text = "Lets your Engineer fix breakdowns (2-4 is good)"
		var at_cap: bool = GameState.RESOURCE_CAPS.has(res_key) and have >= float(GameState.RESOURCE_CAPS[res_key])
		(card["buy"] as Button).disabled = credits < _price(item) or at_cap
		(card["sell"] as Button).disabled = res_key == "hull" or have < float(item["amount"])


func _leave() -> void:
	SaveManager.save_game()
	goto("travel")
