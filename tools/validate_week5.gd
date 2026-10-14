# Real scene/button/input/physics integration; no visual or listening claims.
extends SceneTree
var failures := 0
var session: Node

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int = 5) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func press_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await frames()

func _initialize() -> void:
	run_checks.call_deferred()

func run_checks() -> void:
	session = root.get_node("GameSession")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/ui/main_menu.tscn", "Startup is not menu")
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await frames()
	check(not session.running, "Menu must not count time")
	check(current_scene.get_node("%Start").has_focus(), "Keyboard focus missing")
	var music: AudioStreamPlayer = session.get_node("BackgroundMusic")
	var delivery: AudioStreamPlayer = session.get_node("DeliverySFX")
	var hazard: AudioStreamPlayer = session.get_node("HazardSFX")
	check(music.playing, "Music did not start")
	check(music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Music not looping")
	check(music.stream.loop_begin == 0 and music.stream.loop_end == 264600, "Wrong music loop bounds")
	check(music.bus == &"Music" and delivery.bus == &"SFX" and hazard.bus == &"SFX", "Wrong audio routing")
	for bus in ["Master", "Music", "SFX"]:
		check(AudioServer.get_bus_index(bus) >= 0, "Missing bus: " + bus)
	check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) == -15.0, "Wrong music volume")
	check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")) == -5.0, "Wrong SFX volume")
	# Wait through one full 12-second phrase using the engine audio clock.
	await create_timer(12.2).timeout
	check(music.playing, "Music stopped at loop boundary")
	check(music.get_playback_position() < music.stream.get_length(), "Music position did not wrap")
	check(session.elapsed_seconds == 0.0, "Menu time advanced")
	var music_id := music.get_instance_id()
	current_scene.get_node("%Start").pressed.emit()
	await frames()
	check(current_scene.name == "Level1", "Start did not load Level 1")
	check(current_scene.get_node("HUD") is CanvasLayer, "HUD is not CanvasLayer")
	var hud := current_scene.get_node("HUD")
	check(hud.get_node("%LevelLabel").text == "Level 1 / 2", "Wrong level indicator")
	var initial: float = session.elapsed_seconds
	await frames(70)
	check(session.elapsed_seconds > initial + 0.5, "Timer not advancing")
	check(hud.get_node("%TimerLabel").text != "Time: 00:00", "Visible timer not updating")
	# Layout bounds at the project viewport, including the existing 64px header space.
	check(hud.get_node("Header").size.y <= 64, "Header covers gameplay")
	check(hud.get_node("%Status").get_global_rect().end.x <= root.get_visible_rect().end.x, "HUD overflows horizontally")
	var player: CharacterBody2D = current_scene.get_node("Player")
	player.position = current_scene.get_node("Hazards/Puddle1").position
	await frames(3)
	check(hazard.playing, "Puddle SFX did not start")
	check(player.position == current_scene.get_node("Start").position, "Puddle reset failed")
	var before_restart: float = session.elapsed_seconds
	var old_level := current_scene.get_instance_id()
	await press_key(KEY_R)
	check(current_scene.name == "Level1" and current_scene.get_instance_id() != old_level, "R did not restart")
	check(session.elapsed_seconds >= before_restart, "Restart lost elapsed time")
	player = current_scene.get_node("Player")
	player.position = current_scene.get_node("Goal").position
	var before_goal: float = session.elapsed_seconds
	await frames()
	check(current_scene.name == "Level2", "Goal did not load Level 2")
	check(delivery.playing, "Delivery SFX missing across transition")
	check(session.elapsed_seconds >= before_goal, "Level transition reset timer")
	check(music.get_instance_id() == music_id and music.playing, "Music did not persist")
	check(current_scene.get_node("HUD/%LevelLabel").text == "Level 2 / 2", "Level 2 indicator missing")
	player = current_scene.get_node("Player")
	player.position = current_scene.get_node("Goal").position
	await frames()
	check(not session.running, "Completion did not stop timer")
	var finished_time: float = session.elapsed_seconds
	await frames(10)
	check(session.elapsed_seconds == finished_time, "Completed timer still advances")
	check(current_scene.get_node("HUD/Completion").visible, "Completion panel missing")
	check(current_scene.get_node("HUD/%FinalTime").text == "Time: " + session.time_text(), "Final time mismatch")
	check(current_scene.get_node("HUD/%PlayAgain").has_focus(), "Completion keyboard focus missing")
	check(not player.is_physics_processing(), "Completed player still moves")
	check(not player.get_node("MovementDust").emitting, "Completed dust still emits")
	current_scene.get_node("HUD/%PlayAgain").pressed.emit()
	await frames()
	check(current_scene.name == "Level1" and session.elapsed_seconds < 1.0, "Play Again did not reset run")
	await press_key(KEY_ESCAPE)
	check(current_scene.name == "MainMenu" and not session.running, "Escape failed")
	# Completion's Main Menu button is separately wired and tested.
	session.change_scene("res://scenes/levels/level_2.tscn")
	await frames()
	current_scene.get_node("Player").position = current_scene.get_node("Goal").position
	await frames()
	current_scene.get_node("HUD/%MainMenu").pressed.emit()
	await frames()
	check(current_scene.name == "MainMenu", "Completion menu button failed")
	print("Week 5 integration checks: %d failures" % failures)
	if failures == 0:
		current_scene.get_node("%Quit").pressed.emit()
	else:
		session.stop_audio()
		await frames(10)
		quit(1)
