extends Node2D

@export_file("*.tscn") var next_level: String = ""
var finished := false
var resetting := false

@onready var enemy: CharacterBody2D = get_node_or_null("Enemy")

func _ready() -> void:
	GameSession.enter_level()
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
	_reset_player.call_deferred(message)

func _reset_player(message: String) -> void:
	$Player.global_position = $Start.global_position
	$Player.velocity = Vector2.ZERO
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
	if not next_level.is_empty():
		var error := get_tree().change_scene_to_file(next_level)
		if error != OK:
			finished = false
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
