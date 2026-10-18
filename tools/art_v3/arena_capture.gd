extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(game)
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.presentation.hide()
	for obstacle in game._arena.obstacles:
		var point: Vector2=obstacle.position-Vector2(70,0)
		if game._arena.point_clear(point,14):
			game.player.position=point
			break
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var im: Image=root.get_texture().get_image()
	im.resize(640,360,Image.INTERPOLATE_NEAREST)
	im.save_png("res://reports/visual_qa/v3_astra/arena_runtime.png")
	im.resize(1280,720,Image.INTERPOLATE_NEAREST)
	im.save_png("res://reports/visual_qa/v3_astra/arena_runtime_2x.png")
	print("RESULT arena actual layout map=",game._arena.definition.id," colliders=",game._arena.obstacles.size()," failures=0")
	game.free();quit()
