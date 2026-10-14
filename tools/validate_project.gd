# Load scripts/resources with project autoloads available. Standalone --check-only
# does not initialize autoload names used by the UI and level scripts.
extends SceneTree
var failures := 0
var checked := 0

func _initialize() -> void:
	validate.call_deferred()

func scan(path: String) -> void:
	for filename in DirAccess.get_files_at(path):
		if filename.get_extension() not in ["gd", "tscn", "tres"]:
			continue
		var full_path := path.path_join(filename)
		var resource := load(full_path)
		checked += 1
		if resource == null or (resource is GDScript and not resource.can_instantiate()):
			failures += 1
			push_error("Invalid resource: " + full_path)
	for directory in DirAccess.get_directories_at(path):
		scan(path.path_join(directory))

func validate() -> void:
	for directory in ["res://scenes", "res://resources", "res://tools"]:
		scan(directory)
	for path in ["res://main.tscn", "res://default_bus_layout.tres"]:
		checked += 1
		if load(path) == null:
			failures += 1
	print("Project resources checked: %d; failures: %d" % [checked, failures])
	root.get_node("GameSession").stop_audio()
	await create_timer(0.2).timeout
	quit(0 if failures == 0 else 1)
