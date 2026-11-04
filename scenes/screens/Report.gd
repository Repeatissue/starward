extends BaseScreen
## End-of-run screen: victory epilogue or loss, plus score.

const MISSING_ROLE_EPILOGUES := {
	"Medic": "Without a medic, the first fever season on Earth 2 took a heavy toll.",
	"Scientist": "With no scientist to test the soil, the first crops failed. The colony lived on ship rations through a hungry winter.",
	"Engineer": "No one left understood the ship's reactor. The colonists stripped it for parts and built their first homes by hand.",
	"Pilot": "With no pilot to bring her down gently, the landing scattered cargo across half a valley.",
	"Security": "With no one keeping the peace, the colony's first year was full of quarrels and factions.",
}


func build() -> void:
	SaveManager.delete_save()
	if GameState.victory:
		Platform.unlock_achievement("first_landfall")

	var root := make_root(64, 16)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	var heading := "LANDFALL" if GameState.victory else "LOST IN THE DARK"
	root.add_child(UIKit.label(heading, 56, UIKit.GOOD if GameState.victory else UIKit.BAD))
	root.add_child(UIKit.para(GameState.end_reason, 24))

	var living := GameState.living_crew()
	root.add_child(UIKit.label("Days travelled: %d" % GameState.day, 22, UIKit.DIM))
	root.add_child(UIKit.label("Colonists alive: %d / %d" % [GameState.colonists, GameState.STARTING_COLONISTS], 22, UIKit.DIM))
	var names: Array = living.map(func(c): return c["name"])
	root.add_child(UIKit.para("Crew surviving: %s" % (", ".join(PackedStringArray(names)) if not names.is_empty() else "none"), 22, UIKit.DIM))

	if GameState.victory:
		root.add_child(UIKit.spacer(8))
		for line in _epilogue():
			root.add_child(UIKit.para(line, 22))
		root.add_child(UIKit.spacer(8))
		root.add_child(UIKit.label("SCORE: %d   (%s, x%s)" % [
			GameState.score(), GameState.background.get("name", "?"), str(GameState.background.get("score_mult", 1))], 32, UIKit.ACCENT))

	root.add_child(UIKit.spacer(16))
	var row := UIKit.hbox()
	row.add_child(UIKit.button("New Journey", func(): goto("new_run"), 260))
	row.add_child(UIKit.button("Main Menu", func(): goto("menu"), 260))
	root.add_child(row)


func _epilogue() -> Array:
	var lines: Array = []
	for role in MISSING_ROLE_EPILOGUES:
		if not GameState.has_role(role):
			lines.append(MISSING_ROLE_EPILOGUES[role])
	var survival := float(GameState.colonists) / float(GameState.STARTING_COLONISTS)
	if lines.is_empty() and survival > 0.9:
		lines.append("Every role filled, nearly every pod accounted for. The colony of Earth 2 begins as well as anyone could have hoped.")
	elif survival < 0.5:
		lines.append("So few woke. The settlement was built around a memorial before it had a school.")
	else:
		lines.append("It wasn't the arrival anyone dreamed of, but it was an arrival.")
	return lines
