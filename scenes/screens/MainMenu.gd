extends BaseScreen


func build() -> void:
	var planet := PlanetView.new()
	planet.show_ship = true
	planet.anchor_left = 0.4
	planet.anchor_right = 1.0
	planet.anchor_top = 0.0
	planet.anchor_bottom = 1.0
	add_child(planet)

	var root := make_root(72, 18)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	var col := UIKit.vbox(16)
	col.custom_minimum_size = Vector2(520, 0)
	col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	root.add_child(col)

	col.add_child(UIKit.title("STARWARD", 78, UIKit.ACCENT))
	col.add_child(UIKit.title("THE LONG HAUL TO EARTH 2", 20, UIKit.INFO))
	col.add_child(UIKit.para("200 colonists asleep in the hold. 48 light-units of dark between you and a new home. One second-hand ship.", 20, UIKit.DIM))
	col.add_child(UIKit.spacer(18))

	var new_btn := UIKit.primary_button("NEW JOURNEY", func(): goto("new_run"), 340)
	new_btn.custom_minimum_size.y = 58
	new_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(new_btn)

	var cont_btn := UIKit.button("Continue", _on_continue, 340)
	cont_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cont_btn.disabled = not SaveManager.has_save()
	col.add_child(cont_btn)

	if Platform.can_quit():
		var quit_btn := UIKit.button("Quit", func(): get_tree().quit(), 340)
		quit_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		col.add_child(quit_btn)

	col.add_child(UIKit.spacer(30))
	col.add_child(UIKit.label("Prototype build", 14, UIKit.DIM))
	new_btn.grab_focus()


func _on_continue() -> void:
	if SaveManager.load_game():
		goto("travel")
