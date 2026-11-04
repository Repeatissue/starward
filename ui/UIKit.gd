class_name UIKit
extends RefCounted
## Builds the shared theme and common widgets. Touch-friendly sizes by default (iOS-ready).

const MIN_TOUCH := 48

const BG := Color("0b1020")
const PANEL := Color("131a2e")
const BORDER := Color("2a3a5e")
const TEXT := Color("e8d9b0")
const ACCENT := Color("ffb347")
const DIM := Color("8a93a8")
const GOOD := Color("7fd18b")
const BAD := Color("ff6b6b")


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 22
	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, BORDER))
	t.set_stylebox("normal", "Button", _box(Color("1c2742"), BORDER))
	t.set_stylebox("hover", "Button", _box(Color("26365c"), ACCENT))
	t.set_stylebox("pressed", "Button", _box(Color("33497a"), ACCENT))
	t.set_stylebox("disabled", "Button", _box(Color("141a2b"), Color("1f2840")))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), ACCENT))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", ACCENT)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", DIM)
	t.set_stylebox("normal", "LineEdit", _box(Color("1c2742"), BORDER))
	t.set_stylebox("focus", "LineEdit", _box(Color("1c2742"), ACCENT))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_stylebox("background", "ProgressBar", _box(Color("1c2742"), BORDER, 0))
	t.set_stylebox("fill", "ProgressBar", _box(ACCENT, ACCENT, 0))
	return t


static func _box(bg: Color, border: Color, padding: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(padding)
	return s


## Single-line label.
static func label(text: String, size: int = 22, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## Wrapping paragraph that fills the available width.
static func para(text: String, size: int = 22, color: Color = TEXT) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func button(text: String, on_press: Callable, min_width: int = 0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, MIN_TOUCH)
	b.pressed.connect(on_press)
	return b


static func hbox(separation: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	return h


static func vbox(separation: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v


static func panel() -> PanelContainer:
	return PanelContainer.new()


static func spacer(height: int = 16) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c


## Horizontal filler that pushes following items to the right.
static func filler() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c
