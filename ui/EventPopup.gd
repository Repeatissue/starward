class_name EventPopup
extends Control
## Modal event card: illustration, story, choices, then the outcome with coloured change chips.

var event: Dictionary = {}
var on_closed: Callable
var _box: VBoxContainer
var _card: PanelContainer


func setup(ev: Dictionary, closed_callback: Callable) -> void:
	event = ev
	on_closed = closed_callback


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.01, 0.04, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_card = UIKit.panel("CardPanel")
	_card.custom_minimum_size = Vector2(820, 0)
	center.add_child(_card)
	_box = UIKit.vbox(12)
	_card.add_child(_box)
	_show_choices()
	_card.pivot_offset = _card.size / 2.0
	_card.scale = Vector2(0.94, 0.94)
	_card.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(_card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "modulate:a", 1.0, 0.15)


func _clear() -> void:
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()


func _header() -> void:
	_box.add_child(EventArt.new(event.get("art", "void"), event["id"]))
	_box.add_child(UIKit.title(str(event["title"]).to_upper(), 26, UIKit.ACCENT))


func _show_choices() -> void:
	_clear()
	_header()
	_box.add_child(UIKit.para(event["text"], 19))
	if event.get("notice", false):
		# A warning card (e.g. supplies running out): nothing to choose, just acknowledge.
		var row := UIKit.hbox()
		row.add_child(UIKit.filler())
		var ok := UIKit.primary_button("UNDERSTOOD", _close, 220)
		row.add_child(ok)
		_box.add_child(row)
		ok.call_deferred("grab_focus")
		return
	_box.add_child(UIKit.heading("WHAT DO YOU DO?"))
	var n := 1
	for choice in event["choices"]:
		var b := UIKit.button("%d.  %s" % [n, EventEngine.choice_label(choice)], func(): _choose(choice))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var ok := EventEngine.is_choice_available(choice)
		b.disabled = not ok
		if not ok:
			b.tooltip_text = "You don't meet the requirement in brackets."
		_box.add_child(b)
		if n == 1 and ok:
			b.call_deferred("grab_focus")
		n += 1


func _choose(choice: Dictionary) -> void:
	var result := EventEngine.resolve_choice(event, choice)
	_clear()
	_header()
	var text: String = result["text"]
	if text != "":
		_box.add_child(UIKit.para(text, 19))
	var changes: Array = result["changes"]
	if not changes.is_empty():
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		for ch in changes:
			flow.add_child(UIKit.chip(ch["text"], UIKit.GOOD if ch["good"] else UIKit.BAD, ch["kind"]))
		_box.add_child(flow)
	var row := UIKit.hbox()
	row.add_child(UIKit.filler())
	var cont := UIKit.primary_button("CONTINUE", _close, 220)
	row.add_child(cont)
	_box.add_child(row)
	cont.call_deferred("grab_focus")


func _close() -> void:
	queue_free()
	if on_closed.is_valid():
		on_closed.call()
