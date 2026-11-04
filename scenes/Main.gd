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


func _ready() -> void:
	theme = UIKit.make_theme()
	starfield = Starfield.new()
	add_child(starfield)
	goto("menu")


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
