extends BaseScreen
## The main journey screen: ship status, crew, log and travel controls.

var _res_labels: Dictionary = {}
var _crew_box: VBoxContainer
var _location_label: Label
var _leg_label: Label
var _progress: ProgressBar
var _log: RichTextLabel
var _travel_btn: Button
var _trade_btn: Button
var _thrust_opt: OptionButton
var _ration_opt: OptionButton
var _popup: EventPopup = null
var _shown_log := 0


func build() -> void:
	var root := make_root(24, 12)

	# Header
	var header := UIKit.hbox()
	_location_label = UIKit.label("", 30, UIKit.ACCENT)
	_location_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_location_label)
	header.add_child(UIKit.button("Save & Menu", _on_menu, 200))
	root.add_child(header)
	_leg_label = UIKit.label("", 20, UIKit.DIM)
	root.add_child(_leg_label)
	_progress = ProgressBar.new()
	_progress.custom_minimum_size = Vector2(0, 14)
	_progress.show_percentage = false
	root.add_child(_progress)

	# Body: status on the left, log on the right
	var body := UIKit.hbox(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var left := UIKit.vbox(12)
	left.custom_minimum_size = Vector2(400, 0)
	body.add_child(left)

	var res_panel := UIKit.panel()
	left.add_child(res_panel)
	var res_box := UIKit.vbox(2)
	res_panel.add_child(res_box)
	res_box.add_child(UIKit.label("SHIP: %s" % GameState.SHIP_NAME, 18, UIKit.DIM))
	for key in GameState.RESOURCE_KEYS + ["colonists"]:
		var row := UIKit.hbox()
		var name_text: String = GameState.RESOURCE_NAMES.get(key, "Colonists")
		var n := UIKit.label(name_text, 20)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(n)
		var v := UIKit.label("", 20)
		row.add_child(v)
		res_box.add_child(row)
		_res_labels[key] = v

	var crew_panel := UIKit.panel()
	crew_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(crew_panel)
	var crew_scroll := ScrollContainer.new()
	crew_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	crew_panel.add_child(crew_scroll)
	_crew_box = UIKit.vbox(6)
	_crew_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crew_scroll.add_child(_crew_box)

	var log_panel := UIKit.panel()
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(log_panel)
	_log = RichTextLabel.new()
	_log.scroll_following = true
	_log.selection_enabled = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 20)
	log_panel.add_child(_log)

	# Controls
	var controls := UIKit.hbox(12)
	root.add_child(controls)
	controls.add_child(UIKit.label("Thrust", 20, UIKit.DIM))
	_thrust_opt = _make_option(GameState.THRUST, GameState.thrust, _on_thrust)
	controls.add_child(_thrust_opt)
	controls.add_child(UIKit.label("Rations", 20, UIKit.DIM))
	_ration_opt = _make_option(GameState.RATIONS, GameState.rations, _on_rations)
	controls.add_child(_ration_opt)
	controls.add_child(UIKit.filler())
	_trade_btn = UIKit.button("Dock & Trade", _on_trade, 200)
	controls.add_child(_trade_btn)
	_travel_btn = UIKit.button("Continue Journey >", _on_travel, 280)
	controls.add_child(_travel_btn)

	_refresh()
	_travel_btn.grab_focus()


func _make_option(options: Dictionary, selected: String, callback: Callable) -> OptionButton:
	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(170, UIKit.MIN_TOUCH)
	for key in options:
		opt.add_item(options[key]["name"])
	opt.select(options.keys().find(selected))
	opt.item_selected.connect(callback)
	return opt


func _on_thrust(index: int) -> void:
	GameState.thrust = GameState.THRUST.keys()[index]
	_refresh()


func _on_rations(index: int) -> void:
	GameState.rations = GameState.RATIONS.keys()[index]
	_refresh()


func _on_trade() -> void:
	goto("outfitter", {"mode": "departure" if GameState.node_index == 0 else "station"})


func _on_menu() -> void:
	SaveManager.save_game()
	goto("menu")


func _on_travel() -> void:
	if _popup != null:
		return
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
	_location_label.text = "Day %d  |  %s" % [GameState.day, node["name"]]
	if not nxt.is_empty():
		var t: Dictionary = GameState.THRUST[GameState.thrust]
		var remaining := float(nxt["distance"]) - GameState.progress
		var days := ceili(remaining / float(t["speed"]))
		_leg_label.text = "Next: %s (%s)  -  %.1f light-units, about %d days at %s. Journey %d%% complete." % [
			nxt["name"], nxt["sector_name"], remaining, days, t["name"],
			int(100.0 * GameState.distance_travelled() / maxf(1.0, GameState.total_distance()))]
		_progress.max_value = float(nxt["distance"])
		_progress.value = GameState.progress

	var low := {"fuel": 15.0, "food": 15.0, "oxygen": 15.0, "power": 10.0, "hull": 40.0}
	for key in _res_labels:
		var label: Label = _res_labels[key]
		var value: float = float(GameState.colonists) if key == "colonists" else GameState.get_res(key)
		label.text = str(int(value))
		var is_low: bool = low.has(key) and value < float(low[key])
		label.add_theme_color_override("font_color", UIKit.BAD if is_low else UIKit.TEXT)

	for child in _crew_box.get_children():
		_crew_box.remove_child(child)
		child.queue_free()
	_crew_box.add_child(UIKit.label("CREW", 18, UIKit.DIM))
	for c in GameState.crew:
		if c["alive"]:
			_crew_box.add_child(UIKit.label("%s - %s (%s)" % [c["name"], c["role"], c["trait"]], 19))
			var hp := float(c["health"])
			var color := UIKit.BAD if hp < 30.0 else UIKit.DIM
			_crew_box.add_child(UIKit.label("   Health %d   Morale %d" % [int(hp), int(c["morale"])], 17, color))
		else:
			_crew_box.add_child(UIKit.label("%s - %s  (deceased)" % [c["name"], c["role"]], 19, UIKit.DIM))

	_trade_btn.visible = node["type"] == "station"
	_travel_btn.disabled = GameState.ended

	var lines: Array = GameState.log_lines
	if _shown_log > lines.size():
		_log.clear()
		_shown_log = 0
	for i in range(_shown_log, lines.size()):
		_log.add_text(str(lines[i]) + "\n")
	_shown_log = lines.size()
