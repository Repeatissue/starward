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
	var win := GameState.victory
	if win:
		Platform.unlock_achievement("first_landfall")

	var root := make_root(48, 16)
	var body := UIKit.hbox(32)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var art: Control
	if win:
		var planet := PlanetView.new()
		planet.show_ship = true
		art = planet
	else:
		art = EventArt.new("wreck", "game_over_%d" % GameState.run_seed)
	art.custom_minimum_size = Vector2(460, 0)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(art)

	var col := UIKit.vbox(12)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(col)
	col.add_child(UIKit.title("LANDFALL" if win else "LOST IN THE DARK", 52, UIKit.GOOD if win else UIKit.BAD))
	col.add_child(UIKit.para(GameState.end_reason, 20))

	var stats := HFlowContainer.new()
	stats.add_theme_constant_override("h_separation", 8)
	stats.add_theme_constant_override("v_separation", 8)
	stats.add_child(UIKit.chip("%d days" % GameState.day, UIKit.DIM, "time"))
	if win:
		stats.add_child(UIKit.chip("%d / %d colonists delivered" % [GameState.colonists, GameState.STARTING_COLONISTS], Icons.color_for("colonists"), "colonists"))
		stats.add_child(UIKit.chip("%d crew survived" % GameState.living_crew().size(), UIKit.TEXT, "crew"))
	else:
		stats.add_child(UIKit.chip("%d colonists lost with the ship" % GameState.colonists, UIKit.BAD, "colonists"))
		stats.add_child(UIKit.chip("Journey %d%% complete" % int(GameState.journey_fraction() * 100.0), UIKit.DIM, "waypoint"))
	stats.add_child(UIKit.chip("Hull %d" % int(GameState.get_res("hull")), Icons.color_for("hull"), "hull"))
	col.add_child(stats)

	if win:
		var epi := UIKit.panel("AdvisorPanel")
		var ev := UIKit.vbox(6)
		ev.add_child(UIKit.heading("THE COLONY'S FIRST YEAR", UIKit.ACCENT))
		for line in _epilogue():
			ev.add_child(UIKit.para(line, 17))
		epi.add_child(ev)
		col.add_child(epi)
	col.add_child(UIKit.title("SCORE  %d" % GameState.score(), 34, UIKit.ACCENT))
	var mult := str(GameState.background.get("score_mult", 1))
	if win:
		col.add_child(UIKit.para("Colonists x10, surviving crew x200, hull x2, credits / 10, then x%s for %s." % [mult, GameState.background.get("name", "?")], 15, UIKit.DIM))
	else:
		col.add_child(UIKit.para("Journey %d%% complete: up to 1,000 points for distance, then x%s for %s. Reach Earth 2 for the full score." % [
			int(GameState.journey_fraction() * 100.0), mult, GameState.background.get("name", "?")], 15, UIKit.DIM))

	col.add_child(UIKit.spacer(10))
	var row := UIKit.hbox()
	var again := UIKit.primary_button("NEW JOURNEY", func(): goto("new_run"), 240)
	row.add_child(again)
	row.add_child(UIKit.button("Main Menu", func(): goto("menu"), 200))
	col.add_child(row)
	again.grab_focus()


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
