class_name RouteChooser
extends Control
## "Chart your course": a large star map plus one card per reachable stop.
## Each card says what the stop is, how long it takes, and what you'd have left on arrival,
## so the decision is quick to read. Works with touch, mouse, keyboard, gamepad or Siri Remote
## (left/right moves between cards, select sets course, back closes).

const TYPE_INFO := {
	"station": ["STATION", "Trade and resupply here."],
	"hazard": ["HAZARD", "A shortcut, but dangerous."],
	"derelict": ["DERELICT", "Salvage to be had, with some risk."],
	"waypoint": ["UNKNOWN", "Something waits out there."],
	"quiet": ["QUIET SPACE", "Nothing expected. A safe, steady leg."],
	"destination": ["EARTH 2", "Journey's end."],
}

var on_chosen: Callable
var on_cancel: Callable
var _map: RouteMap


func setup(chosen_callback: Callable, cancel_callback: Callable) -> void:
	on_chosen = chosen_callback
	on_cancel = cancel_callback


var _focus_trap: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_focus_trap = UIKit.trap_focus(get_parent(), self)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.01, 0.04, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := UIKit.panel("CardPanel")
	card.custom_minimum_size = Vector2(1120, 0)
	center.add_child(card)
	var box := UIKit.vbox(12)
	card.add_child(box)

	var head := UIKit.hbox(12)
	head.add_child(UIKit.title("CHART YOUR COURSE", 28, UIKit.ACCENT))
	head.add_child(UIKit.filler())
	head.add_child(UIKit.label("Day %d  |  leaving %s" % [GameState.day, GameState.current_node()["name"]], 16, UIKit.DIM))
	box.add_child(head)

	_map = RouteMap.new()
	_map.node_radius = 15.0
	_map.label_options = true
	_map.custom_minimum_size = Vector2(0, 230)
	var map_panel := UIKit.panel()
	map_panel.add_child(_map)
	box.add_child(map_panel)

	box.add_child(UIKit.heading("WHERE NEXT, CAPTAIN?"))
	var row := UIKit.hbox(12)
	box.add_child(row)
	var first: Button = null
	for opt in GameState.route_options():
		var b := _option_card(row, opt)
		if first == null:
			first = b

	var foot := UIKit.hbox()
	foot.add_child(UIKit.para("Hazards are shortcuts, stations cost more days but let you resupply. Arrival forecasts assume your current thrust and rations.", 14, UIKit.DIM))
	foot.add_child(UIKit.button("Back", _cancel, 160))
	box.add_child(foot)
	if first:
		first.call_deferred("grab_focus")


func _option_card(row: HBoxContainer, opt: Dictionary) -> Button:
	var kind: String = opt["type"]
	var info: Array = TYPE_INFO.get(kind, ["", ""])
	var col := Icons.color_for(kind)
	var card := UIKit.panel()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(card)
	var v := UIKit.vbox(6)
	card.add_child(v)

	var top := UIKit.hbox(10)
	top.add_child(IconView.new(kind, 40))
	var tv := UIKit.vbox(0)
	tv.add_child(UIKit.label(str(opt["name"]), 20, UIKit.TEXT))
	tv.add_child(UIKit.heading(info[0], col))
	top.add_child(tv)
	v.add_child(top)

	var days := ceili(float(opt["distance"]) / GameState.speed())
	var blurb: String = info[1]
	if opt.get("event", "") == "nix_haven_toll":
		blurb = "Pirate haven: trade here, but they charge a toll."
	elif kind == "station" and int(opt["sector"]) > 0:
		blurb = "Trade and resupply (prices +%d%%)." % int(round(25.0 * int(opt["sector"])))
	v.add_child(UIKit.label("%s away" % GameState.days(days), 18, UIKit.ACCENT))
	v.add_child(UIKit.para(blurb, 15, UIKit.DIM))

	# What you'd have left on arrival
	var short: Array = []
	for key in ["fuel", "food", "oxygen"]:
		var left := GameState.days_left(key) - days
		if left < 3.0:
			short.append(GameState.RESOURCE_NAMES[key].to_lower())
	if short.is_empty():
		v.add_child(UIKit.para("Supplies: fine for this leg.", 14, UIKit.GOOD))
	else:
		v.add_child(UIKit.para("Low on arrival: %s." % ", ".join(PackedStringArray(short)), 14, UIKit.BAD))

	var onward: Array = []
	for nid in opt.get("next", []):
		onward.append(str(GameState.map_node(nid).get("name", "?")))
	if not onward.is_empty():
		v.add_child(UIKit.para("Leads on to: %s" % ", ".join(PackedStringArray(onward)), 13, UIKit.DIM))

	v.add_child(UIKit.spacer(2))
	var go := UIKit.primary_button("SET COURSE", func(): _choose(opt["id"]))
	go.focus_entered.connect(func(): _map.highlight_id = opt["id"])
	go.mouse_entered.connect(func(): _map.highlight_id = opt["id"])
	v.add_child(go)
	return go


func _choose(id: String) -> void:
	GameState.choose_route(id)
	UIKit.release_focus_trap(_focus_trap)
	queue_free()
	if on_chosen.is_valid():
		on_chosen.call()


func _cancel() -> void:
	UIKit.release_focus_trap(_focus_trap)
	queue_free()
	if on_cancel.is_valid():
		on_cancel.call()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel()
