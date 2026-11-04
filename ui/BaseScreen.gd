class_name BaseScreen
extends Control
## Base for every full-screen view. Main.gd creates screens and swaps between them.
## Subclasses override build() and create their UI in code.

var main  # Main.gd (untyped to avoid a circular reference)
var params: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build()


func build() -> void:
	pass


func goto(screen: String, p: Dictionary = {}) -> void:
	main.goto(screen, p)


## Full-screen margin with a vertical layout inside. Returns the layout to fill.
func make_root(margin_px: int = 32, separation: int = 16) -> VBoxContainer:
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, margin_px)
	add_child(m)
	var v := UIKit.vbox(separation)
	m.add_child(v)
	return v
