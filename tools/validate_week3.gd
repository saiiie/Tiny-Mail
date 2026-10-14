# Headless integration checks use real physics overlap signals.
extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int = 5) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func _initialize() -> void:
	run_checks.call_deferred()

func run_checks() -> void:
	for number in [1, 2]:
		var packed: PackedScene = load("res://scenes/levels/level_%d.tscn" % number)
		check(packed != null, "Missing level scene")
		var level := packed.instantiate()
		root.add_child(level)
		current_scene = level
		await frames()
		var player: CharacterBody2D = level.get_node("Player")
		var ground: TileMapLayer = level.get_node("Ground")
		var walls: TileMapLayer = level.get_node("HedgesAndFences")
		check(ground.get_used_cells().size() == 600, "Ground tiles not saved")
		check(walls.get_used_cells().size() > 0, "Boundary tiles missing")
		check(walls.tile_set.get_physics_layers_count() == 1, "TileSet collisions missing")
		check(player.scene_file_path == "res://scenes/player/player.tscn", "Original Player not reused")
		check(player.is_in_group("week3_player"), "Player group not saved")
		check(level.get_node("Hazards").get_child_count() == (2 if number == 1 else 5), "Wrong puddle count")
		for hazard in level.get_node("Hazards").get_children():
			player.global_position = hazard.global_position
			await frames()
			check(player.global_position.distance_to(level.get_node("Start").global_position) < 1.0, "Puddle failed to reset player")
		# Walk left from START into the hedge, using unchanged movement input.
		Input.action_press("move_left")
		await frames(40)
		Input.action_release("move_left")
		check(player.position.x >= 79.0, "Player passed through hedge")
		player.global_position = level.get_node("Goal").global_position
		await frames(10)
		if number == 1:
			check(current_scene.scene_file_path == "res://scenes/levels/level_2.tscn", "Level 1 did not transition")
		else:
			check(level.get_node("HUD/Completion").visible, "Completion message missing")
			check(not player.is_physics_processing(), "Player should stop after completion")
		current_scene.queue_free()
		await frames()
	print("Week 3 integration checks: %d failures" % failures)
	root.get_node("GameSession").stop_audio()
	await frames(10)
	quit(0 if failures == 0 else 1)
