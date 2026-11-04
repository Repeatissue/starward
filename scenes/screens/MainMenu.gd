extends BaseScreen


func build() -> void:
	var root := make_root(64, 20)
	root.alignment = BoxContainer.ALIGNMENT_CENTER

	var title := UIKit.label("STARWARD", 72, UIKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	var sub := UIKit.label("The Long Haul to Earth 2", 28)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)
	root.add_child(UIKit.spacer(24))

	var new_btn := UIKit.button("New Journey", func(): goto("new_run"), 360)
	new_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(new_btn)

	var cont_btn := UIKit.button("Continue", _on_continue, 360)
	cont_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cont_btn.disabled = not SaveManager.has_save()
	root.add_child(cont_btn)

	if Platform.can_quit():
		var quit_btn := UIKit.button("Quit", func(): get_tree().quit(), 360)
		quit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		root.add_child(quit_btn)

	root.add_child(UIKit.spacer(24))
	var note := UIKit.label("Prototype build. Placeholder art.", 16, UIKit.DIM)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(note)
	new_btn.grab_focus()


func _on_continue() -> void:
	if SaveManager.load_game():
		goto("travel")
