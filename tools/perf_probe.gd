extends Node
## Measures per-screen rendering cost (CPU/GPU ms, draw calls, primitives) with vsync off.
## Run (needs a window):  godot --path . res://tools/perf_probe.tscn

const SAMPLE_SECONDS := 2.0


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	print("screen        fps    frame_ms  render_cpu  render_gpu  draw_calls  primitives")
	await _probe("menu")
	GameState.new_run(1234, Data.backgrounds[0])
	main.goto("outfitter", {"mode": "departure"})
	await _probe("outfitter")
	main.goto("travel")
	await _probe("travel")
	var popup := EventPopup.new()
	popup.setup(Data.events_by_id["belt_crossing"], func(): pass)
	main.current.add_child(popup)
	await _probe("event")
	get_tree().quit()


func _probe(label: String) -> void:
	await get_tree().create_timer(0.8).timeout
	var frames := 0
	var cpu := 0.0
	var gpu := 0.0
	var calls := 0.0
	var prims := 0.0
	var vp := get_viewport().get_viewport_rid()
	var start := Time.get_ticks_usec()
	while Time.get_ticks_usec() - start < SAMPLE_SECONDS * 1000000.0:
		await get_tree().process_frame
		frames += 1
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
		calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var secs := (Time.get_ticks_usec() - start) / 1000000.0
	print("%-12s %5d  %8.2f  %10.2f  %10.2f  %10d  %10d" % [label, int(frames / secs), 1000.0 * secs / frames,
		cpu / frames, gpu / frames, int(calls / frames), int(prims / frames)])
