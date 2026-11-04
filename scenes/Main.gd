extends Control
## Root of the game. Owns the theme and swaps between screens.

const SCREENS := {
	"menu": preload("res://scenes/screens/MainMenu.gd"),
	"new_run": preload("res://scenes/screens/NewRun.gd"),
	"outfitter": preload("res://scenes/screens/Outfitter.gd"),
	"travel": preload("res://scenes/screens/Travel.gd"),
	"report": preload("res://scenes/screens/Report.gd"),
}

var current: BaseScreen = null


func _ready() -> void:
	theme = UIKit.make_theme()
	var bg := ColorRect.new()
	bg.color = UIKit.BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	goto("menu")


func goto(screen: String, p: Dictionary = {}) -> void:
	if current != null:
		current.queue_free()
	var s: BaseScreen = SCREENS[screen].new()
	s.main = self
	s.params = p
	add_child(s)
	current = s


## Save when the window closes or the app goes to the background (important on iOS).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save_game()
