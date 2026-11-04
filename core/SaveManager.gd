extends Node
## Saves the run as JSON in user://. Steam Cloud (Phase 4) and iCloud (Phase 5)
## can sync this file without code changes here.

const SAVE_PATH := "user://savegame.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	if not GameState.run_active or GameState.ended:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Could not write save: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(GameState.to_dict(), "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary):
		push_error("Save file is corrupt.")
		return false
	GameState.from_dict(d)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
