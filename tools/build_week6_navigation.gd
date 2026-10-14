# Rebuild only the navigation resource from the saved Level 2 path tiles/puddles.
# Run explicitly: godot --headless --path . --script tools/build_week6_navigation.gd
extends SceneTree

func _initialize() -> void:
	build.call_deferred()

func build() -> void:
	# Do not add the level to the tree: no gameplay runs while baking.
	var level: Node2D = load("res://scenes/levels/level_2.tscn").instantiate()
	var ground: TileMapLayer = level.get_node("Ground")
	var geometry := NavigationMeshSourceGeometryData2D.new()
	for cell in ground.get_used_cells_by_id(1):
		var center := ground.position + ground.map_to_local(cell)
		geometry.add_traversable_outline(rect_outline(center, Vector2(16, 16)))
	for puddle in level.get_node("Hazards").get_children():
		# Exclude the visible 32x32 puddle, then the bake adds enemy clearance.
		geometry.add_obstruction_outline(rect_outline(puddle.position, Vector2(16, 16)))
	var polygon := NavigationPolygon.new()
	polygon.agent_radius = 12.0
	polygon.cell_size = 1.0
	NavigationServer2D.bake_from_source_geometry_data(polygon, geometry)
	if polygon.get_polygon_count() == 0:
		push_error("Navigation bake produced no polygons")
		quit(1)
		return
	var error := ResourceSaver.save(polygon, "res://resources/level_2_navigation.tres")
	print("Saved Level 2 navigation: %d polygons, result %s" % [polygon.get_polygon_count(), error])
	level.free()
	root.get_node("GameSession").stop_audio()
	await create_timer(0.2).timeout
	quit(0 if error == OK else 1)

func rect_outline(center: Vector2, half_size: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(-half_size.x, -half_size.y),
		center + Vector2(half_size.x, -half_size.y),
		center + Vector2(half_size.x, half_size.y),
		center + Vector2(-half_size.x, half_size.y)
	])
