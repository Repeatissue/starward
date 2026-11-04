extends Node
## Remote-only navigation test: drives the game with nothing but arrows, select and back
## (what a Siri Remote or gamepad sends) to prove every screen works without touch or mouse.
## Run:  godot --headless --path . res://tools/nav_test.tscn

var main: Node
var failures := 0


func _ready() -> void:
	SaveManager.delete_save()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _wait()
	_check("menu focuses New Journey", _focused_text().contains("NEW JOURNEY"))
	await _press("ui_accept")
	_check("select opens captain screen", main.current.get_script().resource_path.ends_with("NewRun.gd"))
	_check("captain screen focuses a Choose button", _focused_text() == "CHOOSE")
	await _press("ui_down")
	await _press("ui_accept")
	_check("choosing a captain opens the outfitter", main.current.get_script().resource_path.ends_with("Outfitter.gd"))
	_check("outfitter focuses Launch", _focused_text().contains("LAUNCH"))
	await _press("ui_accept")
	_check("launch opens travel", main.current.get_script().resource_path.ends_with("Travel.gd"))
	_check("travel focuses the main button", _focused_text().contains("CHART COURSE"))
	await _press("ui_accept")
	var chooser := _find(main.current, "RouteChooser")
	_check("select opens the route chooser", chooser != null)
	var before := get_viewport().gui_get_focus_owner()
	await _press("ui_right")
	var after := get_viewport().gui_get_focus_owner()
	print("    focus before: %s  after: %s" % [_describe(before), _describe(after)])
	_check("right arrow moves between route cards", after != null and after != before and _focused_text() == "SET COURSE")
	await _press("ui_cancel")
	_check("back closes the route chooser", _find(main.current, "RouteChooser") == null)
	await _press("ui_accept")
	await _press("ui_accept")
	_check("select on a card sets a course", not GameState.next_node().is_empty() or GameState.day > 1)
	# Clear any event/warning cards with select (one press at a time) until none are open.
	for i in 12:
		if _find(main.current, "EventPopup") == null:
			break
		await _press("ui_accept")
	print("    before back: screen=%s popups=%s focus=%s" % [main.current.get_script().resource_path.get_file(),
		str(main.current.get_children().map(func(c): return c.get_script().get_global_name() if c.get_script() else c.get_class())), _describe(get_viewport().gui_get_focus_owner())])
	await _press("ui_cancel")
	_check("back on travel goes to the menu (and saves)", main.current.get_script().resource_path.ends_with("MainMenu.gd") and SaveManager.has_save())
	print("NAV TEST: %s (%d failure%s)" % ["PASS" if failures == 0 else "FAIL", failures, "" if failures == 1 else "s"])
	SaveManager.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _wait()
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await _wait()


func _wait() -> void:
	for i in 4:
		await get_tree().process_frame


func _focused_text() -> String:
	var f := get_viewport().gui_get_focus_owner()
	return (f as Button).text if f is Button else ""


func _describe(c: Control) -> String:
	if c == null:
		return "none"
	return "%s '%s' @%s" % [c.get_class(), (c as Button).text if c is Button else "", str(c.global_position.round())]


func _find(root: Node, cls: String) -> Node:
	for c in root.get_children():
		if c.get_script() and str(c.get_script().get_global_name()) == cls:
			return c
	return null


func _check(label: String, ok: bool) -> void:
	print("  [%s] %s" % ["ok" if ok else "FAIL", label])
	if not ok:
		failures += 1
