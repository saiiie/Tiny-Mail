extends Node

const LEVEL_ONE := "res://scenes/levels/level_1.tscn"
const MENU := "res://scenes/ui/main_menu.tscn"
var elapsed_seconds := 0.0
var running := false
var changing_scene := false

func _ready() -> void:
	# Explicit full-stream loop, independent of editor import defaults.
	var music := $BackgroundMusic.stream as AudioStreamWAV
	music.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.loop_begin = 0
	music.loop_end = int(round(music.get_length() * music.mix_rate))
	$BackgroundMusic.play()

func _process(delta: float) -> void:
	if running and not changing_scene:
		elapsed_seconds += delta

func time_text() -> String:
	var total := int(elapsed_seconds)
	return "%02d:%02d" % [total / 60, total % 60]

func enter_level() -> void:
	changing_scene = false
	running = true

func enter_menu() -> void:
	changing_scene = false
	running = false
	$DeliverySFX.stop()
	$HazardSFX.stop()

func start_game() -> void:
	if changing_scene:
		return
	elapsed_seconds = 0.0
	change_scene(LEVEL_ONE)

func restart_level() -> void:
	if changing_scene or get_tree().current_scene == null:
		return
	change_scene(get_tree().current_scene.scene_file_path)

func return_to_menu() -> void:
	change_scene(MENU)

func change_scene(path: String) -> void:
	if changing_scene:
		return
	changing_scene = true
	_apply_scene_change.call_deferred(path)

func _apply_scene_change(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		changing_scene = false
		push_error("Could not load %s: %s" % [path, error])

func finish_run() -> void:
	running = false

func play_delivery() -> void:
	$DeliverySFX.play()

func play_hazard() -> void:
	$HazardSFX.play()

func stop_audio() -> void:
	for player in get_children():
		if player is AudioStreamPlayer:
			player.stop()

func _exit_tree() -> void:
	stop_audio()
