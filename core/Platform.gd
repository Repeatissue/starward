extends Node
## Thin wrapper over platform services. Every Steam / Game Center call goes through here,
## so the Apple builds swap the backend without touching gameplay code.
##
## Targets: Windows / macOS / Linux / Steam Deck (Steam), iPhone and iPad (iOS), Apple TV (tvOS).
## tvOS export is not in an official Godot release yet (see GAME_DESIGN_AND_PLAN.md), so the game is
## built to be ready for it: remote-only navigation, TV-safe margins, no Quit, no hover-only info.

## Title-safe margins for TV, in canvas pixels at the 1280x800 base size (about 5% each side).
const TV_SAFE_X := 64
const TV_SAFE_Y := 40

var backend: String = "none"
var _steam: Object = null


func _ready() -> void:
	if Engine.has_singleton("Steam"):
		_steam = Engine.get_singleton("Steam")
		backend = "steam"
		# TODO (Phase 4): initialise GodotSteam here, e.g. _steam.steamInitEx().
	elif is_apple_device():
		backend = "apple"


func is_tv() -> bool:
	# STARWARD_TV=1 lets you preview the TV layout on a desktop.
	return OS.has_feature("tvos") or OS.get_name() == "tvOS" or OS.has_feature("tv") or OS.get_environment("STARWARD_TV") == "1"


func is_apple_device() -> bool:
	return OS.has_feature("ios") or is_tv() or OS.has_feature("visionos")


func unlock_achievement(id: String) -> void:
	match backend:
		"steam":
			pass  # TODO (Phase 4): _steam.setAchievement(id); _steam.storeStats()
		"apple":
			pass  # TODO (Phase 5): Game Center (shared by iPhone, iPad and Apple TV)
		_:
			print("[Platform] Achievement unlocked: %s" % id)


## Apple platforms must not show a Quit button.
func can_quit() -> bool:
	return not is_apple_device()


## Free text entry is awkward with a TV remote, so optional text fields are hidden on TV.
func allows_text_entry() -> bool:
	return not is_tv()
