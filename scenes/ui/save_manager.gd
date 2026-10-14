extends Node

const SAVE_PATH := "user://tiny_post_save.json"
const LEVELS := ["res://scenes/levels/level_1.tscn", "res://scenes/levels/level_2.tscn"]

func save_game(level: String, elapsed: float) -> bool:
	if level not in LEVELS or not is_finite(elapsed) or elapsed < 0.0:
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save Tiny Post progress.")
		return false
	file.store_string(JSON.stringify({"version": 1, "level": level, "elapsed_seconds": elapsed}))
	file.flush()
	return file.get_error() == OK

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return {}
	var data: Dictionary = json.data
	if data.get("version") != 1 or data.get("level") not in LEVELS:
		return {}
	if not ResourceLoader.exists(data["level"], "PackedScene"):
		return {}
	var elapsed: Variant = data.get("elapsed_seconds")
	if not (elapsed is float or elapsed is int):
		return {}
	if not is_finite(float(elapsed)) or float(elapsed) < 0.0:
		return {}
	return data

func has_save() -> bool:
	return not load_game().is_empty()

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var error := DirAccess.remove_absolute(SAVE_PATH)
		if error != OK:
			push_warning("Could not clear Tiny Post save: %s" % error)
