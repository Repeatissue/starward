extends Node
## Renders every screen and saves PNGs to screenshots/ (for store pages, reviews and checking the UI).
## Run (needs a window, not headless):  godot --path . res://tools/screenshots.tscn

const OUT := "res://screenshots/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _shot("1_menu")
	main.goto("new_run")
	await _shot("2_captain")

	GameState.new_run(1234, Data.backgrounds[1])
	main.goto("outfitter", {"mode": "departure"})
	await _shot("3_outfitter")

	for key in {"fuel": 110.0, "food": 200.0, "oxygen": 60.0, "parts": 1.0}.keys():
		GameState.add_resource(key, {"fuel": 110.0, "food": 200.0, "oxygen": 60.0, "parts": 1.0}[key])
	GameState.add_resource("credits", -700.0)
	for i in 4:
		var r := TravelSim.travel()
		if r.get("type", "") == "event":
			for choice in r["event"]["choices"]:
				if EventEngine.is_choice_available(choice):
					EventEngine.resolve_choice(r["event"], choice)
					break
	main.goto("travel")
	await _shot("4_travel")

	var popup := EventPopup.new()
	popup.setup(Data.events_by_id["belt_crossing"], func(): pass)
	main.current.add_child(popup)
	await _shot("5_event")

	GameState.add_resource("hull", -65.0)
	GameState.rations = "reduced"
	GameState.thrust = "overdrive"
	main.goto("travel")
	await _shot("6_travel_damaged")

	GameState.end_run(true, "Day %d. The ISV Wayfarer settles into orbit above Earth 2. %d colonists wake to a new sky." % [GameState.day, GameState.colonists])
	main.goto("report")
	await _shot("7_report")
	get_tree().quit()


func _shot(file_name: String) -> void:
	await get_tree().create_timer(0.7).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + file_name + ".png"))
	print("Saved ", file_name)
