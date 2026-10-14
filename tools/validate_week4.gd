extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int = 4) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func _initialize() -> void:
	run_checks.call_deferred()

func run_checks() -> void:
	for number in [1, 2]:
		var level: Node = load("res://scenes/levels/level_%d.tscn" % number).instantiate()
		root.add_child(level)
		current_scene = level
		await frames()
		var player: CharacterBody2D = level.get_node("Player")
		var animation: AnimationPlayer = player.get_node("AnimationPlayer")
		var dust: GPUParticles2D = player.get_node("MovementDust")
		var sprite: Sprite2D = player.get_node("Sprite2D")
		check(animation.current_animation == "idle", "Initial idle missing")
		check(not dust.emitting, "Initial dust must be off")
		check(sprite.texture.resource_path.ends_with("char_mail_carrier_idle.png"), "Wrong idle texture")
		for direction in ["down", "up", "left", "right"]:
			var name: String = "move_" + direction
			check(animation.has_animation(name), "Missing " + name)
			var clip := animation.get_animation(name)
			check(clip.loop_mode == Animation.LOOP_LINEAR, "Walk must loop")
			check(clip.track_get_key_count(0) == 2, "Walk needs two frames")
			check(clip.track_get_path(0) == NodePath("Sprite2D:texture"), "Wrong animation target")
			for index in range(2):
				var texture: Texture2D = clip.track_get_key_value(0, index)
				check(texture.resource_path.ends_with("char_mail_carrier_%s_%d.png" % [direction, index + 1]), "Wrong walk frame")
			# Test playback of each texture directly, then real input-driven state.
			animation.play(name)
			for index in range(2):
				animation.seek(float(index) / 48.0 + 0.001, true)
				check(sprite.texture == clip.track_get_key_value(0, index), "Texture track failed")
			player.position = level.get_node("Start").position
			Input.action_press(name)
			await frames()
			check(animation.current_animation == name, "Input did not select " + name)
			check(dust.emitting, "Moving dust must emit")
			# Calling visual update again must not rewind an existing animation.
			animation.seek(0.025, true)
			player._process(0.0)
			check(is_equal_approx(animation.current_animation_position, 0.025), "Animation restarted")
			Input.action_release(name)
			await frames()
			check(animation.current_animation == "idle", "Idle did not resume")
			check(not dust.emitting, "Idle dust must stop")
		# The existing completion code disables player physics.
		player.velocity = Vector2(220, 0)
		player.set_physics_process(false)
		await frames()
		check(animation.current_animation == "idle" and not dust.emitting, "Completion visuals did not stop")
		level.queue_free()
		await frames()
	check(FileAccess.get_file_as_string("res://README.md").contains("## Week 4 - Art, Animation & Particles"), "Week 4 documentation missing")
	print("Week 4 integration checks: %d failures" % failures)
	root.get_node("GameSession").stop_audio()
	await frames(10)
	quit(0 if failures == 0 else 1)
