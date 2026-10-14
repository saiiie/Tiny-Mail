# Run explicitly with: godot --headless --path . --script tools/build_week3.gd
# Rebuilds the saved Week 3 layouts; not needed when playing.
extends SceneTree

func _initialize() -> void:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(32, 32)
	tiles.add_physics_layer()
	tiles.set_physics_layer_collision_layer(0, 1)
	var names := ["grass", "path", "bush_32x32", "flowers", "tree", "fence"]
	for index in range(names.size()):
		var atlas := TileSetAtlasSource.new()
		atlas.texture = load("res://assets/tiles/%s.png" % names[index])
		atlas.texture_region_size = Vector2i(32, 32)
		atlas.create_tile(Vector2i.ZERO)
		tiles.add_source(atlas, index)
		if index == 2 or index == 5:
			var data := atlas.get_tile_data(Vector2i.ZERO, 0)
			data.set_collision_polygons_count(0, 1)
			data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-16,-16), Vector2(16,-16), Vector2(16,16), Vector2(-16,16)]))
	DirAccess.make_dir_recursive_absolute("res://resources")
	assert(ResourceSaver.save(tiles, "res://resources/neighborhood.tres") == OK)
	tiles.take_over_path("res://resources/neighborhood.tres")
	for number in [1, 2]:
		build_level(number, tiles)
	quit()

func attach(parent: Node, child: Node, level: Node) -> void:
	parent.add_child(child)
	child.owner = level

func label_at(parent: Node, level: Node, title: String, message: String, pos: Vector2, width: float, size: int = 18) -> Label:
	var label := Label.new()
	label.name = title
	label.text = message
	label.position = pos
	label.size.x = width
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	attach(parent, label, level)
	return label

func build_level(number: int, tiles: TileSet) -> void:
	var level := Node2D.new()
	level.name = "Level%d" % number
	level.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	level.set_script(load("res://scenes/levels/week3_level.gd"))
	if number == 1:
		level.set("next_level", "res://scenes/levels/level_2.tscn")
	var route: Array[Rect2i] = []
	if number == 1:
		route = [Rect2i(2,14,25,4), Rect2i(23,4,4,14)]
	else:
		route = [Rect2i(2,15,10,3), Rect2i(9,9,3,9), Rect2i(9,9,13,3), Rect2i(19,3,3,9), Rect2i(19,3,8,3)]
	var walkable: Dictionary = {}
	for rect in route:
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				walkable[Vector2i(x,y)] = true
	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.position.y = 64
	ground.tile_set = tiles
	attach(level, ground, level)
	var borders := TileMapLayer.new()
	borders.name = "HedgesAndFences"
	borders.position.y = 64
	borders.tile_set = tiles
	attach(level, borders, level)
	for y in range(20):
		for x in range(30):
			var cell := Vector2i(x,y)
			ground.set_cell(cell, 1 if walkable.has(cell) else 0, Vector2i.ZERO)
			if not walkable.has(cell):
				var edge := x == 0 or x == 29 or y == 0 or y == 19
				var adjacent := false
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					adjacent = adjacent or walkable.has(cell + offset)
				if edge or adjacent:
					borders.set_cell(cell, 5 if edge else 2, Vector2i.ZERO)
				elif (x * 7 + y * 11) % 17 == 0:
					borders.set_cell(cell, 3 if x % 2 == 0 else 4, Vector2i.ZERO)
	var start := Marker2D.new()
	start.name = "Start"
	start.position = Vector2(112, 576 if number == 2 else 560)
	attach(level, start, level)
	label_at(level, level, "StartLabel", "START", start.position + Vector2(-28, 24), 80, 16)
	var player: CharacterBody2D = load("res://scenes/player/player.tscn").instantiate()
	player.name = "Player"
	player.position = start.position
	player.add_to_group("week3_player", true)
	attach(level, player, level)
	var hazards := Node2D.new()
	hazards.name = "Hazards"
	attach(level, hazards, level)
	var positions: Array[Vector2] = []
	if number == 1:
		positions = [Vector2(336,576), Vector2(784,384)]
	else:
		positions = [Vector2(240,608), Vector2(304,496), Vector2(496,368), Vector2(656,304), Vector2(752,176)]
	for index in range(positions.size()):
		var hazard: Area2D = load("res://hazard.tscn").instantiate()
		hazard.name = "Puddle%d" % (index + 1)
		hazard.position = positions[index]
		attach(hazards, hazard, level)
	var goal: Area2D = load("res://scenes/objects/goal.tscn").instantiate()
	goal.name = "Goal"
	goal.position = Vector2(800, 240 if number == 1 else 208)
	attach(level, goal, level)
	for pos in [Vector2(160,240), Vector2(480,208), Vector2(496,496)]:
		var house := Sprite2D.new()
		house.name = "NeighborHouse"
		house.texture = load("res://assets/objects/obj_house.png")
		house.position = pos
		attach(level, house, level)
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	attach(level, hud, level)
	var background := ColorRect.new()
	background.name = "Header"
	background.size = Vector2(960,64)
	background.color = Color("263c38")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	attach(hud, background, level)
	label_at(hud, level, "Title", "TINY POST  |  Level %d / 2  |  WASD or arrows: move" % number, Vector2(16,4), 928, 20)
	label_at(hud, level, "Status", "Follow the path to DELIVER HERE. Avoid puddles; no timer, unlimited retries.", Vector2(16,34), 928, 17)
	var completion := Panel.new()
	completion.name = "Completion"
	completion.position = Vector2(200,280)
	completion.size = Vector2(560,120)
	completion.visible = false
	attach(hud, completion, level)
	var message := label_at(completion, level, "Message", "All mail delivered!\nBoth neighborhoods complete. Well done!", Vector2(20,25), 520, 24)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var packed := PackedScene.new()
	assert(packed.pack(level) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/levels/level_%d.tscn" % number) == OK)
	level.free()
