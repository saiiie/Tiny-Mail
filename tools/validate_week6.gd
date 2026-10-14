# Headless physics tests: real navigation, Area2D signals, resets and completion.
extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int = 5) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func _initialize() -> void:
	run_checks.call_deferred()

func clear_of_puddles(level: Node, point: Vector2) -> bool:
	for puddle in level.get_node("Hazards").get_children():
		var nearest := point.clamp(puddle.position - Vector2(16,16), puddle.position + Vector2(16,16))
		if point.distance_to(nearest) < 10.0:
			return false
	return true

func run_checks() -> void:
	change_scene_to_file("res://scenes/levels/level_2.tscn")
	await frames(10)
	var level := current_scene
	var enemy: CharacterBody2D = level.get_node("Enemy")
	var player: CharacterBody2D = level.get_node("Player")
	var agent: NavigationAgent2D = enemy.get_node("NavigationAgent2D")
	var ground: TileMapLayer = level.get_node("Ground")
	check(get_nodes_in_group("week6_enemies").size() == 1, "Expected exactly one enemy")
	check(enemy.state == enemy.State.PATROL, "Enemy must start in PATROL")
	check(enemy.get_node("Body").is_visible_in_tree(), "Enemy visual hidden")
	check(enemy.get_node("Body").polygon.size() >= 3, "Enemy visual has no geometry")
	check(not enemy.get_node("CollisionShape2D").disabled, "Enemy body collision disabled")
	check(level.get_node("NavigationRegion2D").navigation_polygon.get_polygon_count() > 0, "Navigation bake missing")
	for frame in range(120):
		if not agent.get_current_navigation_path().is_empty():
			break
		await frames(1)
	check(agent.get_current_navigation_path().size() >= 3, "Patrol path must navigate the bend")
	check(enemy.patrol_speed < player.speed and enemy.chase_speed < player.speed, "Enemy should be slower than player")
	# Observe a complete there-and-back patrol without manually changing FSM state.
	var last_index: int = enemy.patrol_index
	var switches := 0
	var crossed_blocked_tile := false
	var touched_puddle := false
	var start_position := enemy.position
	for tick in range(1100):
		await frames(1)
		if enemy.patrol_index != last_index:
			switches += 1
			last_index = enemy.patrol_index
		crossed_blocked_tile = crossed_blocked_tile or ground.get_cell_source_id(ground.local_to_map(enemy.position - ground.position)) != 1
		touched_puddle = touched_puddle or not clear_of_puddles(level, enemy.position)
		if switches >= 2:
			break
	check(switches >= 2, "Enemy failed to reach both patrol markers")
	check(enemy.position.distance_to(start_position) > 1.0 or switches >= 2, "Enemy did not move")
	check(not crossed_blocked_tile, "Enemy crossed non-walkable terrain")
	check(not touched_puddle, "Enemy patrol crossed a puddle")
	# Place rabbit and crow on opposite sides of Puddle4. The chase must detour.
	enemy.position = Vector2(656, 368)
	player.position = Vector2(656, 256)
	await frames(5)
	check(enemy.state == enemy.State.CHASE, "Area entry failed to trigger CHASE")
	check(enemy.chase_target == player, "Detection did not store Player")
	check(agent.target_position.distance_to(player.position) < 1.0, "Chase target was not updated")
	check(agent.get_current_navigation_path().size() >= 3, "Chase should path around puddle")
	var chase_start := enemy.position
	await frames(12)
	check(enemy.position.distance_to(chase_start) > 10.0, "Enemy did not move while chasing")
	check(clear_of_puddles(level, enemy.position), "Chase entered puddle")
	player.position = Vector2(680, 256)
	await frames(10)
	check(agent.target_position.distance_to(player.position) < 1.0, "Moving chase target was not refreshed")
	player.position = level.get_node("Start").position
	await frames()
	check(enemy.state == enemy.State.PATROL and enemy.chase_target == null, "Detection exit did not restore PATROL")
	# Actual contact overlap, not a manually emitted signal.
	enemy.reset_patrol()
	await frames()
	var elapsed_before: float = root.get_node("GameSession").elapsed_seconds
	player.position = enemy.position
	await frames(3)
	check(player.position == level.get_node("Start").position, "Enemy contact did not reset Player")
	check(level.get_node("HUD/%Status").text.contains("crow"), "Enemy reset status missing")
	check(enemy.position.distance_to(enemy.spawn_position) < 10.0, "Enemy failed to return to safe patrol spawn")
	check(root.get_node("GameSession/HazardSFX").playing, "Existing reset sound not played")
	check(root.get_node("GameSession").elapsed_seconds >= elapsed_before, "Enemy reset lost timer")
	check(enemy.state == enemy.State.PATROL, "Enemy kept chasing after reset")
	player.position = level.get_node("Goal").position
	await frames()
	check(level.get_node("HUD/Completion").visible, "Completion broken")
	check(not enemy.is_physics_processing(), "Enemy did not stop on completion")
	var finished_position := enemy.position
	await frames(10)
	check(enemy.position == finished_position, "Enemy moved behind completion panel")
	root.get_node("GameSession").restart_level()
	await frames(10)
	check(get_nodes_in_group("week6_enemies").size() == 1, "Restart duplicated enemy")
	check(current_scene.get_node("Enemy").state == 0, "Restart did not restore PATROL")
	root.get_node("GameSession").return_to_menu()
	await frames()
	check(get_nodes_in_group("week6_enemies").is_empty(), "Enemy leaked into menu")
	print("Week 6 integration checks: %d failures; patrol target switches: %d" % [failures, switches])
	root.get_node("GameSession").stop_audio()
	await create_timer(0.2).timeout
	quit(0 if failures == 0 else 1)
