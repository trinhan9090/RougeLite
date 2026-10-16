extends SceneTree
func _initialize() -> void: call_deferred("run_tests")
func run_tests() -> void:
	var checks: int = 0
	var failed: int = 0
	for theme: String in ["enchanted_forest","ruined_temple","volcanic_arena"]:
		var definition := load("res://content/maps/"+theme+".tres") as MapDefinition
		for seed_value in range(100):
			var layout: Array[Rect2] = MapLayoutGenerator.generate(definition,RunRng.new(seed_value).stream(&"obstacles"))
			checks += 1
			if not MapLayoutGenerator.connected(definition,layout) or not MapLayoutGenerator.clear(definition.safe_spawn_anchor,layout,250): failed += 1
			var arena := ArenaGeometry.new()
			arena.definition = definition
			arena.obstacles = layout
			root.add_child(arena)
			checks += 1
			var terrain := arena.get_node("PixelTerrain") as TileMapLayer
			if terrain.get_used_cells().is_empty() or terrain.tile_set.get_physics_layers_count()!=0: failed += 1
			for rect in layout:
				checks += 1
				if arena.spawn_clear(rect.get_center(),14): failed += 1
			arena.free()
			if seed_value%10==0: await process_frame
		print("ART_MAP_SEEDS theme=%s seeds=100" % theme)
	print("RESULT art maps checks=%d failures=%d" % [checks,failed])
	quit(0 if failed==0 else 1)
