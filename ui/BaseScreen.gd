class_name BaseScreen
extends Control
## Base for every full-screen view. Main.gd creates screens and swaps between them.
## Subclasses override build() and create their UI in code.
##
## Every screen must be fully usable with only arrows + select + back, so it works on
## Apple TV (Siri Remote), gamepads and keyboards as well as touch and mouse:
##   - build() should leave a sensible button focused (grab_focus),
##   - on_back() handles the back button (Siri Remote MENU / gamepad B / Escape).

var main  # Main.gd (untyped to avoid a circular reference)
var params: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build()


func build() -> void:
	pass


## Override to handle "back". Default: do nothing.
func on_back() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		on_back()


func goto(screen: String, p: Dictionary = {}) -> void:
	main.goto(screen, p)


## Full-screen margin with a vertical layout inside. Returns the layout to fill.
## On a TV the margin grows to keep everything inside the title-safe area.
func make_root(margin_px: int = 32, separation: int = 16) -> VBoxContainer:
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var horiz := margin_px
	var vert := margin_px
	if Platform.is_tv():
		horiz = maxi(margin_px, Platform.TV_SAFE_X)
		vert = maxi(margin_px, Platform.TV_SAFE_Y)
	m.add_theme_constant_override("margin_left", horiz)
	m.add_theme_constant_override("margin_right", horiz)
	m.add_theme_constant_override("margin_top", vert)
	m.add_theme_constant_override("margin_bottom", vert)
	add_child(m)
	var v := UIKit.vbox(separation)
	m.add_child(v)
	return v
