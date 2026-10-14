extends CanvasLayer

@export_range(1, 2) var level_number := 1
var displayed_second := -1
var feedback_tween: Tween
@onready var timer_label: Label = %TimerLabel

func _ready() -> void:
	%LevelLabel.text = "Level %d / 2" % level_number
	%PlayAgain.pressed.connect(GameSession.start_game)
	%MainMenu.pressed.connect(GameSession.return_to_menu)
	_update_timer()

func _process(_delta: float) -> void:
	_update_timer()

func _update_timer() -> void:
	var second := int(GameSession.elapsed_seconds)
	if second != displayed_second:
		displayed_second = second
		timer_label.text = "Time: " + GameSession.time_text()

func show_feedback(message: String) -> void:
	if feedback_tween != null:
		feedback_tween.kill()
	%Feedback.text = message
	%Feedback.modulate.a = 0.0
	feedback_tween = create_tween()
	feedback_tween.tween_property(%Feedback, "modulate:a", 1.0, 0.15)
	feedback_tween.tween_interval(0.45)
	feedback_tween.tween_property(%Feedback, "modulate:a", 0.0, 0.2)

func set_status(message: String) -> void:
	%Status.text = message

func show_completion() -> void:
	%FinalTime.text = "Time: " + GameSession.time_text()
	$Completion.show()
	$Completion.modulate.a = 0.0
	create_tween().tween_property($Completion, "modulate:a", 1.0, 0.2)
	%PlayAgain.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_level"):
		get_viewport().set_input_as_handled()
		GameSession.restart_level()
	elif event.is_action_pressed("return_to_menu"):
		get_viewport().set_input_as_handled()
		GameSession.return_to_menu()
