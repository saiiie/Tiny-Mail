extends SceneTree

var failures := 0
var save: Node
var session: Node

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func wait(seconds: float = 0.15) -> void:
	await create_timer(seconds, true, false, true).timeout

func _initialize() -> void:
	run_checks.call_deferred()

func run_checks() -> void:
	save = root.get_node("SaveManager")
	session = root.get_node("GameSession")
	# Optional paired runs verify persistence across two separate processes.
	if "--write-checkpoint" in OS.get_cmdline_user_args():
		check(save.save_game(save.LEVELS[1], 65.0), "Cross-process checkpoint write failed")
		session.stop_audio()
		await wait()
		quit(failures)
		return
	if "--read-checkpoint" in OS.get_cmdline_user_args():
		check(save.has_save(), "Checkpoint missing in new process")
		session.continue_game()
		await wait()
		check(current_scene.scene_file_path == save.LEVELS[1], "New process did not restore Level 2")
		check(session.elapsed_seconds >= 65.0 and session.elapsed_seconds < 66.0, "New process did not restore timer")
		print("Cross-process persistence checks: %d failures" % failures)
		session.stop_audio()
		await wait()
		quit(failures)
		return
	save.clear_save()
	check(not save.has_save(), "Missing save considered valid")
	change_scene_to_file(session.MENU)
	await wait()
	check(current_scene.get_node("%Continue").disabled, "Continue enabled without save")
	for bad in ["not JSON", "[]", '{"version":1,"level":"res://main.tscn","elapsed_seconds":3}', '{"version":1,"level":"res://scenes/levels/level_1.tscn","elapsed_seconds":-1}']:
		var file := FileAccess.open(save.SAVE_PATH, FileAccess.WRITE)
		file.store_string(bad)
		file.close()
		check(not save.has_save(), "Invalid save accepted")
	check(save.save_game(save.LEVELS[1], 65.0), "Save write failed")
	check(save.load_game().get("elapsed_seconds") == 65.0, "Timer not persisted")
	change_scene_to_file(session.MENU)
	await wait()
	check(not current_scene.get_node("%Continue").disabled, "Valid save disables Continue")
	current_scene.get_node("%Continue").pressed.emit()
	await wait()
	check(current_scene.scene_file_path == save.LEVELS[1], "Continue failed Level 2")
	check(session.elapsed_seconds >= 65.0 and session.elapsed_seconds < 66.0, "Continue timer incorrect")
	session.start_game()
	await wait()
	check(current_scene.scene_file_path == save.LEVELS[0] and session.elapsed_seconds < 1.0, "New game did not reset")
	check(save.load_game().get("level") == save.LEVELS[0], "New checkpoint incorrect")
	var level := current_scene
	check(level.impact_camera.get_screen_center_position().is_equal_approx(root.get_visible_rect().size / 2.0), "Camera changed level framing")
	level.get_node("Player").position = level.get_node("Hazards/Puddle1").position
	await wait(0.04)
	check(Engine.time_scale < 1.0, "Hit-stop not triggered")
	check(level.is_processing(), "Shake not active")
	await wait(0.16)
	check(Engine.time_scale == 1.0, "Hit-stop did not restore time scale")
	check(level.impact_camera.offset == Vector2.ZERO, "Shake did not end")
	check(level.get_node("Player").position == level.get_node("Start").position, "Impact did not reset")
	level.get_node("Player").position = level.get_node("Goal").position
	await wait(0.2)
	check(level.get_node("HUD/%Feedback").modulate.a > 0.0, "Feedback tween not visible")
	check(save.load_game().get("level") == save.LEVELS[1], "Goal did not save Level 2")
	await wait(0.8)
	check(current_scene.scene_file_path == save.LEVELS[1], "Progression failed")
	session.hit_stop()
	session.return_to_menu()
	await wait()
	check(Engine.time_scale == 1.0, "Scene change left hit-stop active")
	save.clear_save()
	session.continue_game()
	await wait()
	check(current_scene.scene_file_path == save.LEVELS[0], "Missing save did not fall back")
	session.return_to_menu()
	await wait()
	session.continue_game()
	await wait()
	check(current_scene.scene_file_path == save.LEVELS[0], "Continue failed Level 1")
	print("Week 7 integration checks: %d failures" % failures)
	session.stop_audio()
	await wait()
	quit(0 if failures == 0 else 1)
