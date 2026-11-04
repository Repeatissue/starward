extends Node
## Thin wrapper over platform services. Every Steam / Game Center call goes through here,
## so the iOS build swaps the backend without touching gameplay code.

var backend: String = "none"
var _steam: Object = null


func _ready() -> void:
	if Engine.has_singleton("Steam"):
		_steam = Engine.get_singleton("Steam")
		backend = "steam"
		# TODO (Phase 4): initialise GodotSteam here, e.g. _steam.steamInitEx().
	elif OS.get_name() == "iOS":
		backend = "ios"


func unlock_achievement(id: String) -> void:
	match backend:
		"steam":
			pass  # TODO (Phase 4): _steam.setAchievement(id); _steam.storeStats()
		"ios":
			pass  # TODO (Phase 5): Game Center
		_:
			print("[Platform] Achievement unlocked: %s" % id)


## iOS apps must not show a Quit button.
func can_quit() -> bool:
	return OS.get_name() != "iOS"
