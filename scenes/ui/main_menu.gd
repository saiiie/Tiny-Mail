extends Control

func _ready() -> void:
	GameSession.enter_menu()
	%Start.pressed.connect(GameSession.start_game)
	%Continue.disabled = not SaveManager.has_save()
	%Continue.pressed.connect(GameSession.continue_game)
	%Quit.pressed.connect(_quit)
	%Start.grab_focus()

func _quit() -> void:
	%Start.disabled = true
	%Continue.disabled = true
	%Quit.disabled = true
	GameSession.stop_audio()
	# Let the audio server release its streams before the application exits.
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
