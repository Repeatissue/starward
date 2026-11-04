extends Control
## Root of the game. Owns the theme and the starfield, and swaps between screens with a fade.

const SCREENS := {
	"menu": preload("res://scenes/screens/MainMenu.gd"),
	"new_run": preload("res://scenes/screens/NewRun.gd"),
	"outfitter": preload("res://scenes/screens/Outfitter.gd"),
	"travel": preload("res://scenes/screens/Travel.gd"),
	"report": preload("res://scenes/screens/Report.gd"),
}

var current: BaseScreen = null
var starfield: Starfield
var _fps_label: Label
var _fps_timer := 0.0


func _ready() -> void:
	theme = UIKit.make_theme()
	starfield = Starfield.new()
	add_child(starfield)
	_fps_label = UIKit.label("", 14, UIKit.GOOD)
	_fps_label.position = Vector2(8, 4)
	_fps_label.z_index = 100
	_fps_label.visible = false
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fps_label)
	goto("menu")


## F3 toggles a small performance readout (FPS, frame time, draw calls).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_fps_label.visible = not _fps_label.visible


func _process(delta: float) -> void:
	if not _fps_label.visible:
		return
	_fps_timer += delta
	if _fps_timer >= 0.5:
		_fps_timer = 0.0
		_fps_label.text = "%d FPS  |  %.1f ms  |  %d draw calls" % [
			Engine.get_frames_per_second(), 1000.0 / maxf(Engine.get_frames_per_second(), 1.0),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]
		move_child(_fps_label, get_child_count() - 1)


func goto(screen: String, p: Dictionary = {}) -> void:
	if current != null:
		current.queue_free()
	starfield.target_speed = 10.0
	var s: BaseScreen = SCREENS[screen].new()
	s.main = self
	s.params = p
	s.modulate.a = 0.0
	add_child(s)
	current = s
	s.create_tween().tween_property(s, "modulate:a", 1.0, 0.25)


## Save when the window closes or the app goes to the background (important on iOS).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save_game()
