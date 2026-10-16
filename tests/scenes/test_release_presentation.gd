extends SceneTree
func _initialize() -> void: call_deferred("run_tests")
func run_tests() -> void:
	var run := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(run)
	run._spawn_clock = 99999
	run.player.invulnerability_left = 99999
	for level in range(2,11):
		run.progression.add_xp(run.progression.curve.threshold(run.state.current_level)-run.state.current_xp)
		if level == 10 and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/evidence/m5-upgrade.png")
		run.request_upgrade(0)
	for attempt in range(30):
		if is_instance_valid(run.boss): break
		run._spawn_boss()
	if not is_instance_valid(run.boss) or run.boss.position.distance_to(run.player.position) < 550:
		printerr("FAIL release presentation safe boss spawn")
		quit(1)
		return
	# Controlled presentation fixture after verifying the genuine safe spawn.
	run.boss.position = Vector2(200,0)
	run.boss.set_physics_process(false)
	run.boss.warn("circle",24,170,0,1)
	for i in range(15): await physics_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/m5-boss.png")
	run.request_pause()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/m5-pause.png")
	paused = false
	run.queue_free()
	await process_frame
	await process_frame
	print("RESULT release presentation: checks=1 failures=0")
	quit()
