extends Node2D

@export_file("*.tscn") var next_level: String = ""
var finished := false
var resetting := false
var shake_until := 0
var impact_camera: Camera2D

@onready var enemy: CharacterBody2D = get_node_or_null("Enemy")

func _ready() -> void:
	# Fixed top-left framing preserves the existing whole-level view.
	impact_camera = Camera2D.new()
	impact_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(impact_camera)
	set_process(false)
	GameSession.enter_level()
	SaveManager.save_game(scene_file_path, GameSession.elapsed_seconds)
	if enemy != null:
		enemy.player_touched.connect(_on_enemy_touched)
		$HUD.set_status("Watch the crow: it chases nearby rabbits. Touching it resets you.")
	for hazard in $Hazards.get_children():
		hazard.stepped_in.connect(_on_hazard)
	$Goal.reached.connect(_on_goal)
	$Player.global_position = $Start.global_position

func _on_hazard(_body: Node2D) -> void:
	_request_reset("Splash! Back at START. Take your time and try again.")

func _on_enemy_touched(_body: Node2D) -> void:
	_request_reset("Caught by the crow! Back at START. Try slipping past it.")

func _request_reset(message: String) -> void:
	if finished or resetting:
		return
	resetting = true
	GameSession.play_hazard()
	GameSession.hit_stop()
	shake_until = Time.get_ticks_msec() + 140
	set_process(true)
	$Player.set_physics_process(false)
	$Player.velocity = Vector2.ZERO
	# Real-time timer keeps the reset short even during hit-stop.
	await get_tree().create_timer(0.08, true, false, true).timeout
	_reset_player.call_deferred(message)

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() >= shake_until:
		impact_camera.offset = Vector2.ZERO
		set_process(false)
	else:
		impact_camera.offset = Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))

func _exit_tree() -> void:
	GameSession.end_hit_stop()

func _reset_player(message: String) -> void:
	$Player.global_position = $Start.global_position
	$Player.velocity = Vector2.ZERO
	$Player.set_physics_process(true)
	if enemy != null:
		enemy.reset_patrol()
	$HUD.set_status(message)
	resetting = false

func _on_goal(_body: Node2D) -> void:
	if finished or resetting:
		return
	finished = true
	GameSession.play_delivery()
	_finish_delivery.call_deferred()

func _finish_delivery() -> void:
	$Player.velocity = Vector2.ZERO
	$Player.set_physics_process(false)
	if enemy != null:
		enemy.stop()
	GameSession.running = false
	var checkpoint := next_level if not next_level.is_empty() else scene_file_path
	var saved := SaveManager.save_game(checkpoint, GameSession.elapsed_seconds)
	$HUD.show_feedback("Delivery Complete!" + (" Progress Saved" if saved else ""))
	if not next_level.is_empty():
		await get_tree().create_timer(0.85).timeout
		var error := get_tree().change_scene_to_file(next_level)
		if error != OK:
			finished = false
			$Player.set_physics_process(true)
			GameSession.running = true
			$HUD.set_status("Could not load Level 2. Please restart.")
			push_error("Level transition failed: %s" % error)
	else:
		$Player.velocity = Vector2.ZERO
		$Player.set_physics_process(false)
		if enemy != null:
			enemy.stop()
		GameSession.finish_run()
		$HUD.set_status("All mail delivered! Thank you for playing.")
		$HUD.show_completion()
