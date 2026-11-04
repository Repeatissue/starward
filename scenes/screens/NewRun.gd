extends BaseScreen
## Pick a captain background and (optionally) a seed.

const DIFFICULTY_COLORS := {"Easy": UIKit.GOOD, "Medium": UIKit.ACCENT, "Hard": UIKit.BAD}

var _seed_edit: LineEdit


func build() -> void:
	var root := make_root(40, 14)
	root.add_child(UIKit.title("CHOOSE YOUR CAPTAIN", 36, UIKit.ACCENT))
	root.add_child(UIKit.para("Your background decides your starting credits. Harder starts multiply your score when you reach Earth 2.", 18, UIKit.DIM))
	root.add_child(UIKit.spacer(4))

	for bg in Data.backgrounds:
		var card := UIKit.panel("CardPanel")
		var row := UIKit.hbox(20)
		card.add_child(row)
		row.add_child(IconView.new(bg["id"], 64))
		var info := UIKit.vbox(6)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_row := UIKit.hbox(12)
		name_row.add_child(UIKit.title(str(bg["name"]).to_upper(), 22, UIKit.TEXT))
		var diff: String = bg.get("difficulty", "Medium")
		name_row.add_child(UIKit.chip(diff.to_upper(), DIFFICULTY_COLORS.get(diff, UIKit.ACCENT)))
		info.add_child(name_row)
		info.add_child(UIKit.para(bg["description"], 17, UIKit.DIM))
		var stats := UIKit.hbox(10)
		stats.add_child(UIKit.chip("%d credits" % int(bg["credits"]), UIKit.KIND_COLORS["credits"], "credits"))
		stats.add_child(UIKit.chip("Score x%s" % str(bg["score_mult"]), UIKit.INFO, "navy"))
		info.add_child(stats)
		row.add_child(info)
		var pick := UIKit.primary_button("CHOOSE", func(): _start(bg), 150)
		pick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pick)
		root.add_child(card)

	root.add_child(UIKit.spacer(4))
	var seed_row := UIKit.hbox()
	seed_row.add_child(UIKit.label("Seed (optional, to replay or share a run):", 17, UIKit.DIM))
	_seed_edit = LineEdit.new()
	_seed_edit.placeholder_text = "random"
	_seed_edit.custom_minimum_size = Vector2(220, UIKit.MIN_TOUCH)
	seed_row.add_child(_seed_edit)
	seed_row.add_child(UIKit.filler())
	seed_row.add_child(UIKit.button("Back", func(): goto("menu"), 150))
	root.add_child(seed_row)


func _start(bg: Dictionary) -> void:
	var run_seed := RNG.new_seed()
	var text := _seed_edit.text.strip_edges()
	if text != "":
		run_seed = text.to_int() if text.is_valid_int() else text.hash()
	SaveManager.delete_save()
	GameState.new_run(run_seed, bg)
	goto("outfitter", {"mode": "departure"})
