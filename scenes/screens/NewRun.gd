extends BaseScreen
## Pick a captain background and (optionally) a seed.

var _seed_edit: LineEdit


func build() -> void:
	var root := make_root()
	root.add_child(UIKit.label("Choose your captain", 40, UIKit.ACCENT))
	root.add_child(UIKit.para("Your background sets your starting credits. Harder starts multiply your score when you reach Earth 2.", 20, UIKit.DIM))

	for bg in Data.backgrounds:
		var card := UIKit.panel()
		var row := UIKit.hbox(16)
		card.add_child(row)
		var info := UIKit.vbox(4)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UIKit.label(bg["name"], 26, UIKit.ACCENT))
		info.add_child(UIKit.para(bg["description"], 18))
		info.add_child(UIKit.label("Credits: %d    Score x%s" % [int(bg["credits"]), str(bg["score_mult"])], 18, UIKit.DIM))
		row.add_child(info)
		var pick := UIKit.button("Choose", func(): _start(bg), 160)
		pick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pick)
		root.add_child(card)

	var seed_row := UIKit.hbox()
	seed_row.add_child(UIKit.label("Seed (optional):", 20, UIKit.DIM))
	_seed_edit = LineEdit.new()
	_seed_edit.placeholder_text = "random"
	_seed_edit.custom_minimum_size = Vector2(260, UIKit.MIN_TOUCH)
	seed_row.add_child(_seed_edit)
	seed_row.add_child(UIKit.filler())
	seed_row.add_child(UIKit.button("Back", func(): goto("menu"), 160))
	root.add_child(seed_row)


func _start(bg: Dictionary) -> void:
	var run_seed := RNG.new_seed()
	var text := _seed_edit.text.strip_edges()
	if text != "":
		run_seed = text.to_int() if text.is_valid_int() else text.hash()
	SaveManager.delete_save()
	GameState.new_run(run_seed, bg)
	goto("outfitter", {"mode": "departure"})
