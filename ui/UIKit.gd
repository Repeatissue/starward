class_name UIKit
extends RefCounted
## Shared theme, colours, fonts and widget helpers. Touch-friendly sizes by default (iOS-ready).

const MIN_TOUCH := 48

const BG := Color("070b18")
const PANEL := Color(0.07, 0.095, 0.17, 0.86)
const CARD := Color(0.1, 0.135, 0.23, 0.92)
const BORDER := Color("2a3a5e")
const TEXT := Color("ece3cc")
const ACCENT := Color("ffb347")
const DIM := Color("8a93a8")
const GOOD := Color("7fd18b")
const BAD := Color("ff6b6b")
const INFO := Color("6ec6ff")

## Colour for each resource / node / icon kind.
const KIND_COLORS := {
	"fuel": Color("ff9f43"),
	"food": Color("7fd18b"),
	"oxygen": Color("6ec6ff"),
	"power": Color("ffe066"),
	"hull": Color("b8c4d6"),
	"parts": Color("c792ea"),
	"credits": Color("ffd54f"),
	"colonists": Color("80deea"),
	"crew": Color("ece3cc"),
	"time": Color("8a93a8"),
	"station": Color("6ec6ff"),
	"hazard": Color("ff8a65"),
	"derelict": Color("b0bec5"),
	"waypoint": Color("c792ea"),
	"destination": Color("7fd18b"),
	"corporate": Color("6ec6ff"),
	"navy": Color("ffd54f"),
	"smuggler": Color("ff8a65"),
}

const ROLE_COLORS := {
	"Pilot": Color("6ec6ff"),
	"Engineer": Color("ff9f43"),
	"Medic": Color("ff6b6b"),
	"Scientist": Color("7fd18b"),
	"Security": Color("c792ea"),
}

const BODY_FONT_PATH := "res://assets/fonts/Exo2.ttf"
const TITLE_FONT_PATH := "res://assets/fonts/Orbitron.ttf"

static var _body: Font
static var _bold: Font
static var _title: Font


static func body_font() -> Font:
	if _body == null:
		_body = _load_font(BODY_FONT_PATH, 500)
	return _body


static func bold_font() -> Font:
	if _bold == null:
		_bold = _load_font(BODY_FONT_PATH, 700)
	return _bold


static func title_font() -> Font:
	if _title == null:
		_title = _load_font(TITLE_FONT_PATH, 700)
	return _title


static func _load_font(path: String, weight: int) -> Font:
	if not ResourceLoader.exists(path):
		return ThemeDB.fallback_font
	var fv := FontVariation.new()
	fv.base_font = load(path)
	var tag := TextServerManager.get_primary_interface().name_to_tag("wght")
	fv.variation_opentype = {tag: weight}
	return fv


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 20
	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, BORDER, 12, 8))

	t.set_stylebox("normal", "Button", _box(Color("1c2742"), BORDER))
	t.set_stylebox("hover", "Button", _box(Color("26365c"), ACCENT))
	t.set_stylebox("pressed", "Button", _box(Color("33497a"), ACCENT))
	t.set_stylebox("disabled", "Button", _box(Color(0.08, 0.1, 0.17, 0.8), Color("1f2840")))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), ACCENT))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", ACCENT)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color(DIM, 0.6))

	# Big amber call-to-action button.
	t.set_type_variation("PrimaryButton", "Button")
	t.set_stylebox("normal", "PrimaryButton", _box(ACCENT, ACCENT.lightened(0.25)))
	t.set_stylebox("hover", "PrimaryButton", _box(ACCENT.lightened(0.15), Color.WHITE))
	t.set_stylebox("pressed", "PrimaryButton", _box(ACCENT.darkened(0.15), ACCENT))
	t.set_stylebox("focus", "PrimaryButton", _box(Color(0, 0, 0, 0), Color.WHITE))
	t.set_stylebox("disabled", "PrimaryButton", _box(Color(0.25, 0.2, 0.12, 0.8), Color(0.3, 0.25, 0.15)))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(state, "PrimaryButton", Color("1a1208"))
	t.set_color("font_disabled_color", "PrimaryButton", Color(0.5, 0.45, 0.35))
	t.set_font("font", "PrimaryButton", bold_font())

	# Segmented toggle buttons (thrust / rations).
	t.set_type_variation("ToggleButton", "Button")
	t.set_stylebox("pressed", "ToggleButton", _box(Color(ACCENT, 0.25), ACCENT))
	t.set_stylebox("hover_pressed", "ToggleButton", _box(Color(ACCENT, 0.32), ACCENT))
	t.set_color("font_pressed_color", "ToggleButton", ACCENT)
	t.set_color("font_hover_pressed_color", "ToggleButton", ACCENT)

	t.set_type_variation("AdvisorPanel", "PanelContainer")
	t.set_stylebox("panel", "AdvisorPanel", _box(Color(0.16, 0.115, 0.05, 0.92), ACCENT, 12, 8))
	t.set_type_variation("CardPanel", "PanelContainer")
	t.set_stylebox("panel", "CardPanel", _box(CARD, BORDER, 14, 8))

	t.set_stylebox("normal", "LineEdit", _box(Color("1c2742"), BORDER))
	t.set_stylebox("focus", "LineEdit", _box(Color("1c2742"), ACCENT))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_stylebox("background", "ProgressBar", _box(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 0))
	t.set_stylebox("fill", "ProgressBar", _box(ACCENT, ACCENT, 0))
	t.set_stylebox("panel", "TooltipPanel", _box(Color("131a2e"), ACCENT, 10))
	t.set_color("font_color", "TooltipLabel", TEXT)
	return t


static func _box(bg: Color, border: Color, padding: int = 12, shadow: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(padding)
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = shadow
	return s


# --- Widgets -------------------------------------------------------------

## Single-line label.
static func label(text: String, size: int = 20, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## Heading in the sci-fi display font.
static func title(text: String, size: int = 32, color: Color = ACCENT) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", title_font())
	return l


## Small spaced-out section heading, e.g. "SHIP STATUS".
static func heading(text: String, color: Color = DIM) -> Label:
	var l := label(text, 13, color)
	l.add_theme_font_override("font", title_font())
	return l


## Wrapping paragraph that fills the available width.
static func para(text: String, size: int = 20, color: Color = TEXT) -> Label:
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


static func primary_button(text: String, on_press: Callable, min_width: int = 0) -> Button:
	var b := button(text, on_press, min_width)
	b.theme_type_variation = "PrimaryButton"
	return b


static func toggle(text: String, group: ButtonGroup, is_on: bool, on_press: Callable, min_width: int = 0) -> Button:
	var b := button(text, on_press, min_width)
	b.theme_type_variation = "ToggleButton"
	b.toggle_mode = true
	b.button_group = group
	b.button_pressed = is_on
	b.add_theme_font_size_override("font_size", 17)
	return b


## Coloured pill with an icon, e.g. "+20 Fuel".
static func chip(text: String, color: Color, icon_kind: String = "") -> PanelContainer:
	var p := PanelContainer.new()
	var s := _box(Color(color, 0.14), Color(color, 0.7), 6)
	s.content_margin_left = 10
	s.content_margin_right = 12
	s.set_corner_radius_all(14)
	p.add_theme_stylebox_override("panel", s)
	var row := hbox(6)
	if icon_kind != "":
		row.add_child(IconView.new(icon_kind, 18, color))
	row.add_child(label(text, 16, color))
	p.add_child(row)
	return p


static func hbox(separation: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	return h


static func vbox(separation: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v


static func panel(variation: String = "") -> PanelContainer:
	var p := PanelContainer.new()
	if variation != "":
		p.theme_type_variation = variation
	return p


static func spacer(height: int = 16) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c


## Horizontal filler that pushes following items to the right.
static func filler() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c
