class_name EventPopup
extends Control
## Modal event card: shows the event, its choices, then the outcome.

var event: Dictionary = {}
var on_closed: Callable
var _box: VBoxContainer


func setup(ev: Dictionary, closed_callback: Callable) -> void:
	event = ev
	on_closed = closed_callback


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := UIKit.panel()
	card.custom_minimum_size = Vector2(760, 0)
	center.add_child(card)
	_box = UIKit.vbox(14)
	card.add_child(_box)
	_show_choices()


func _clear() -> void:
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()


func _show_choices() -> void:
	_clear()
	_box.add_child(UIKit.label(event["title"], 32, UIKit.ACCENT))
	_box.add_child(UIKit.para(event["text"]))
	_box.add_child(UIKit.spacer(4))
	for choice in event["choices"]:
		var b := UIKit.button(EventEngine.choice_label(choice), func(): _choose(choice))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.disabled = not EventEngine.is_choice_available(choice)
		_box.add_child(b)


func _choose(choice: Dictionary) -> void:
	var result := EventEngine.resolve_choice(event, choice)
	_clear()
	_box.add_child(UIKit.label(event["title"], 32, UIKit.ACCENT))
	var text: String = result["text"]
	if text != "":
		_box.add_child(UIKit.para(text))
	var changes: Array = result["changes"]
	if not changes.is_empty():
		_box.add_child(UIKit.para(", ".join(PackedStringArray(changes)), 20, UIKit.ACCENT))
	var row := UIKit.hbox()
	row.add_child(UIKit.filler())
	row.add_child(UIKit.button("Continue", _close, 220))
	_box.add_child(row)


func _close() -> void:
	queue_free()
	if on_closed.is_valid():
		on_closed.call()
