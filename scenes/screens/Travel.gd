extends BaseScreen
## The main journey screen: route map, ship, supplies, crew, advice and travel controls.

const METERS := [
	["fuel", "Fuel", 200.0], ["food", "Food", 300.0], ["oxygen", "Oxygen", 150.0],
	["power", "Power", 100.0], ["hull", "Hull", 100.0], ["parts", "Spare Parts", 6.0],
	["credits", "Credits", 1.0], ["colonists", "Colonists", 200.0],
]
const THRUST_TIPS := {
	"cruise": "Cruise: 1 light-unit a day, 2 fuel a day.\nSlow but easy on the ship.",
	"burn": "Burn: 1.5 light-units a day, 4 fuel a day.\nA little hard on morale.",
	"overdrive": "Overdrive: 2 light-units a day, 7 fuel a day.\nDamages the hull and strains the crew.",
}
const RATION_TIPS := {
	"full": "Full: 1 food per crew member a day.\nThe crew slowly heals.",
	"reduced": "Reduced: 0.6 food per crew member a day.\nMorale drops.",
	"starvation": "Starvation: 0.25 food per crew member a day.\nThe crew loses health fast.",
}
const STARFIELD_SPEED := {"cruise": 14.0, "burn": 24.0, "overdrive": 38.0}

var _meters: Dictionary = {}
var _crew_box: VBoxContainer
var _day_label: Label
var _location_label: Label
var _next_label: Label
var _ship: ShipView
var _route: RouteMap
var _advisor_icon: IconView
var _advisor_text: Label
var _log: RichTextLabel
var _travel_btn: Button
var _trade_btn: Button
var _popup: EventPopup = null
var _shown_log := 0


func build() -> void:
	var root := make_root(18, 10)

	# Top bar
	var top := UIKit.hbox(14)
	_day_label = UIKit.title("", 24, UIKit.ACCENT)
	top.add_child(_day_label)
	_location_label = UIKit.label("", 22)
	top.add_child(_location_label)
	top.add_child(UIKit.filler())
	_next_label = UIKit.label("", 16, UIKit.DIM)
	top.add_child(_next_label)
	top.add_child(UIKit.button("Save & Menu", _on_menu, 160))
	root.add_child(top)

	# Route map
	var route_panel := UIKit.panel()
	_route = RouteMap.new()
	_route.custom_minimum_size = Vector2(0, 110)
	route_panel.add_child(_route)
	root.add_child(route_panel)

	# Body: status | ship + advice + log | crew
	var body := UIKit.hbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var left := UIKit.panel()
	left.custom_minimum_size = Vector2(300, 0)
	body.add_child(left)
	var lbox := UIKit.vbox(3)
	left.add_child(lbox)
	lbox.add_child(UIKit.heading("SHIP STATUS"))
	for m in METERS:
		var meter := Meter.new(m[0], m[1], m[2])
		meter.show_bar = m[0] != "credits"
		lbox.add_child(meter)
		_meters[m[0]] = meter

	var center := UIKit.vbox(10)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(center)
	_ship = ShipView.new()
	_ship.custom_minimum_size = Vector2(0, 140)
	center.add_child(_ship)
	var advisor := UIKit.panel("AdvisorPanel")
	center.add_child(advisor)
	var arow := UIKit.hbox(12)
	advisor.add_child(arow)
	_advisor_icon = IconView.new("crew", 34)
	arow.add_child(_advisor_icon)
	var avbox := UIKit.vbox(2)
	avbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avbox.add_child(UIKit.heading("FIRST OFFICER", UIKit.ACCENT))
	_advisor_text = UIKit.para("", 17)
	avbox.add_child(_advisor_text)
	arow.add_child(avbox)
	var log_panel := UIKit.panel()
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(log_panel)
	var logbox := UIKit.vbox(4)
	log_panel.add_child(logbox)
	logbox.add_child(UIKit.heading("CAPTAIN'S LOG"))
	_log = RichTextLabel.new()
	_log.scroll_following = true
	_log.selection_enabled = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 15)
	_log.add_theme_color_override("default_color", Color(UIKit.TEXT, 0.85))
	logbox.add_child(_log)

	var right := UIKit.panel()
	right.custom_minimum_size = Vector2(280, 0)
	body.add_child(right)
	var rbox := UIKit.vbox(6)
	right.add_child(rbox)
	rbox.add_child(UIKit.heading("CREW"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rbox.add_child(scroll)
	_crew_box = UIKit.vbox(4)
	_crew_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_crew_box)

	# Bottom controls
	var bar := UIKit.panel()
	root.add_child(bar)
	var brow := UIKit.hbox(22)
	bar.add_child(brow)
	brow.add_child(_toggle_group("THRUST", GameState.THRUST, GameState.thrust, THRUST_TIPS, _on_thrust))
	brow.add_child(_toggle_group("RATIONS", GameState.RATIONS, GameState.rations, RATION_TIPS, _on_rations))
	brow.add_child(UIKit.filler())
	_trade_btn = UIKit.button("Dock & Trade", _on_trade, 170)
	_trade_btn.size_flags_vertical = Control.SIZE_SHRINK_END
	brow.add_child(_trade_btn)
	_travel_btn = UIKit.primary_button("CONTINUE JOURNEY  >", _on_travel, 270)
	_travel_btn.custom_minimum_size.y = 56
	_travel_btn.size_flags_vertical = Control.SIZE_SHRINK_END
	brow.add_child(_travel_btn)

	_refresh()
	_travel_btn.grab_focus()


func _toggle_group(title_text: String, options: Dictionary, selected: String, tips: Dictionary, callback: Callable) -> VBoxContainer:
	var v := UIKit.vbox(4)
	v.add_child(UIKit.heading(title_text))
	var row := UIKit.hbox(6)
	var group := ButtonGroup.new()
	for key in options:
		var b := UIKit.toggle(options[key]["name"], group, key == selected, func(): callback.call(key), 106)
		b.tooltip_text = tips.get(key, "")
		row.add_child(b)
	v.add_child(row)
	return v


func _on_thrust(key: String) -> void:
	GameState.thrust = key
	_refresh()


func _on_rations(key: String) -> void:
	GameState.rations = key
	_refresh()


func _on_trade() -> void:
	goto("outfitter", {"mode": "departure" if GameState.node_index == 0 else "station"})


func _on_menu() -> void:
	SaveManager.save_game()
	goto("menu")


func _on_travel() -> void:
	if _popup != null:
		return
	main.starfield.boost(520.0)
	var result := TravelSim.travel()
	_refresh()
	match result.get("type", ""):
		"event":
			_show_event(result["event"])
		"ended":
			goto("report")
		_:
			SaveManager.save_game()


func _show_event(ev: Dictionary) -> void:
	_popup = EventPopup.new()
	_popup.setup(ev, _on_event_closed)
	add_child(_popup)


func _on_event_closed() -> void:
	_popup = null
	_refresh()
	if GameState.ended:
		goto("report")
	else:
		SaveManager.save_game()
		_travel_btn.grab_focus()


func _refresh() -> void:
	var node := GameState.current_node()
	var nxt := GameState.next_node()
	_day_label.text = "DAY %d" % GameState.day
	_location_label.text = str(node["name"])
	if not nxt.is_empty():
		var remaining := float(nxt["distance"]) - GameState.progress
		var days := ceili(remaining / GameState.speed())
		_next_label.text = "Next: %s in ~%d day%s   |   Journey %d%%" % [
			nxt["name"], days, "" if days == 1 else "s",
			int(100.0 * GameState.distance_travelled() / maxf(1.0, GameState.total_distance()))]

	_update_meters()
	_route.refresh()
	_ship.set_thrust(GameState.thrust)
	_ship.damaged = GameState.get_res("hull") < 50.0
	main.starfield.target_speed = STARFIELD_SPEED.get(GameState.thrust, 14.0)

	for child in _crew_box.get_children():
		_crew_box.remove_child(child)
		child.queue_free()
	for c in GameState.crew:
		_crew_box.add_child(CrewCard.new(c))

	var advice := _advice()
	_advisor_text.text = advice[0]
	_advisor_icon.set_icon(advice[1], advice[2])

	_trade_btn.visible = node["type"] == "station"
	_travel_btn.disabled = GameState.ended

	var lines: Array = GameState.log_lines
	if _shown_log > lines.size():
		_log.clear()
		_shown_log = 0
	for i in range(_shown_log, lines.size()):
		_log.add_text(str(lines[i]) + "\n")
	_shown_log = lines.size()


func _update_meters() -> void:
	for key in _meters:
		var meter: Meter = _meters[key]
		match key:
			"colonists":
				meter.set_data(GameState.colonists, "Asleep in cryo pods", GameState.colonists < 150)
			"credits":
				meter.set_data(GameState.get_res("credits"), "Spend at stations", false)
			"hull":
				var hull := GameState.get_res("hull")
				meter.set_data(hull, "Leaking air! Repair at a station" if hull < 50.0 else "Hull integrity", hull < 50.0)
			"parts":
				meter.set_data(GameState.get_res("parts"), "Used for emergency repairs", false)
			"fuel":
				var fuel_days := GameState.days_left("fuel")
				meter.set_data(GameState.get_res("fuel"), "~%d days of thrust (%d light-units)" % [int(fuel_days), int(fuel_days * GameState.speed())], fuel_days < 5.0)
			_:
				var dl := GameState.days_left(key)
				meter.set_data(GameState.get_res(key), "Lasts ~%d days" % int(dl), dl < 6.0)


## Returns [text, icon kind, colour]: the single most useful thing to tell the player right now.
func _advice() -> Array:
	var node := GameState.current_node()
	var stop := GameState.next_stop()
	var stop_name: String = stop["name"]
	var days_to_stop := ceili(float(stop["distance"]) / GameState.speed())
	var at_station: bool = node["type"] == "station"

	var fixes := {
		"oxygen": "Buy O2 canisters, or repair the hull to stop leaks.",
		"food": "Switch to Reduced rations or buy more food.",
		"power": "Buy power cells, or the cryo pods will start failing.",
	}
	for key in ["oxygen", "food", "power"]:
		var dl := GameState.days_left(key)
		if dl < days_to_stop:
			var res_name: String = GameState.RESOURCE_NAMES[key]
			if at_station:
				return ["%s will run out in about %d days, before you reach %s. Tap Dock & Trade now." % [res_name, int(dl), stop_name], key, UIKit.BAD]
			return ["%s runs out in about %d days, but %s is %d days away. %s" % [res_name, int(dl), stop_name, days_to_stop, fixes[key]], key, UIKit.BAD]

	var fuel_range := GameState.days_left("fuel") * GameState.speed()
	if fuel_range < float(stop["distance"]):
		if at_station:
			return ["You don't have enough fuel to reach %s. Buy fuel before you undock." % stop_name, "fuel", UIKit.BAD]
		if GameState.thrust != "cruise":
			return ["Fuel is short for the trip to %s. Drop to Cruise to stretch it." % stop_name, "fuel", UIKit.BAD]
		return ["Fuel won't last to %s. Without it, you'll coast at a crawl." % stop_name, "fuel", UIKit.BAD]

	if GameState.get_res("hull") < 50.0:
		return ["The hull is breached and leaking oxygen. Buy hull plating at the next station.", "hull", UIKit.BAD]

	for c in GameState.living_crew():
		var sick: String = c.get("sick", "")
		if sick != "":
			if GameState.has_role("Medic"):
				return ["%s has %s (health %d). Our Medic is treating them. Full rations speed recovery." % [c["name"], sick, int(c["health"])], "crew", UIKit.BAD]
			return ["%s has %s (health %d) and we have no Medic. Keep rations full and the pace slow." % [c["name"], sick, int(c["health"])], "crew", UIKit.BAD]

	if GameState.get_res("parts") < 1.0:
		return ["We have no spare parts. The next breakdown will cost us days. Buy some at the next station.", "parts", UIKit.ACCENT]

	for c in GameState.living_crew():
		if float(c["health"]) < 35.0:
			return ["%s is badly hurt (health %d). Full rations help the crew recover." % [c["name"], int(c["health"])], "crew", UIKit.ACCENT]

	var morale_total := 0.0
	var living := GameState.living_crew()
	for c in living:
		morale_total += float(c["morale"])
	if not living.is_empty() and morale_total / living.size() < 25.0:
		return ["Morale is collapsing. Full rations and a slower pace will help.", "crew", UIKit.ACCENT]

	if GameState.node_index == 0:
		return ["We're docked at %s. Check our supplies, then press Continue Journey to launch." % node["name"], "station", UIKit.INFO]
	if at_station:
		return ["Docked at %s. Trade if we need anything, then press Continue Journey." % node["name"], "station", UIKit.INFO]
	return ["All systems steady, Captain. %s is about %d days ahead." % [stop_name, days_to_stop], "waypoint", UIKit.GOOD]
