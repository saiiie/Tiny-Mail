extends CanvasLayer

@export_range(1, 2) var level_number := 1

func _ready() -> void:
	%LevelLabel.text = "Level %d / 2" % level_number
	%PlayAgain.pressed.connect(GameSession.start_game)
	%MainMenu.pressed.connect(GameSession.return_to_menu)
	_update_timer()

func _process(_delta: float) -> void:
	_update_timer()

func _update_timer() -> void:
	%TimerLabel.text = "Time: " + GameSession.time_text()

func set_status(message: String) -> void:
	%Status.text = message

func show_completion() -> void:
	%FinalTime.text = "Time: " + GameSession.time_text()
	$Completion.show()
	%PlayAgain.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_level"):
		get_viewport().set_input_as_handled()
		GameSession.restart_level()
	elif event.is_action_pressed("return_to_menu"):
		get_viewport().set_input_as_handled()
		GameSession.return_to_menu()
