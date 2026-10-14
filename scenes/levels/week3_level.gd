extends Node2D

@export_file("*.tscn") var next_level: String = ""
var finished := false
var resetting := false

func _ready() -> void:
	for hazard in $Hazards.get_children():
		hazard.stepped_in.connect(_on_hazard)
	$Goal.reached.connect(_on_goal)
	$Player.global_position = $Start.global_position

func _on_hazard(_body: Node2D) -> void:
	if finished or resetting:
		return
	resetting = true
	_reset_player.call_deferred()

func _reset_player() -> void:
	$Player.global_position = $Start.global_position
	$Player.velocity = Vector2.ZERO
	$HUD/Status.text = "Splash! Back at START. Take your time and try again."
	resetting = false

func _on_goal(_body: Node2D) -> void:
	if finished or resetting:
		return
	finished = true
	_finish_delivery.call_deferred()

func _finish_delivery() -> void:
	if not next_level.is_empty():
		var error := get_tree().change_scene_to_file(next_level)
		if error != OK:
			finished = false
			$HUD/Status.text = "Could not load Level 2. Please restart."
			push_error("Level transition failed: %s" % error)
	else:
		$Player.velocity = Vector2.ZERO
		$Player.set_physics_process(false)
		$HUD/Status.text = "All mail delivered! You completed Tiny Post. Thank you for playing!"
		$HUD/Completion.show()
