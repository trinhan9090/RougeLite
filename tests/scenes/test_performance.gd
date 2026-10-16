extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks += 1
	if value: print("PASS ",label)
	else:
		failures += 1
		printerr("FAIL ",label)
func run_tests() -> void:
	var baseline: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var run := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(run)
	run._spawn_clock = 99999
	run._spawn_config.initial_enemy_cap = 100 # Explicit stress-fixture override of the adaptive production cap.
	run._basic.cooldown_left = 99999
	run.player.invulnerability_left = 99999
	run.audio.enabled = false
	run._arena.apply_layout(run._arena.definition,[])
	for attempt in range(1000):
		if run._enemies.size() >= 100: break
		run.spawn_enemy()
	check(run._enemies.size() == 100,"performance fixture100 actual enemy actors")
	var rank := SkillRankDefinition.new()
	rank.damage = 1
	rank.range_px = 5000
	rank.projectile_speed = 20
	var source: Actor = run.player
	for group in range(5):
		var intent := CastIntent.new()
		intent.source_ref = weakref(source)
		intent.rank = rank
		intent.context = run.combat.next_context(source,&"skill.performance")
		for i in range(60): run.combat.emit_projectile(intent,Vector2.RIGHT.rotated(i*.01),1,null)
	check(run.combat.get_child_count() == 300,"performance fixture300 actual swept projectiles")
	var elapsed: Array[float] = []
	var cpu: Array[float] = []
	var last: int = Time.get_ticks_usec()
	for frame in range(60):
		await process_frame
		var current: int = Time.get_ticks_usec()
		elapsed.append((current-last)/1000.0)
		cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000 + Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
		last = current
	check(run._enemies.size() == 100 and run.combat.get_child_count() == 300,"fixture maintains100 enemies/300 projectiles while processing")
	elapsed.sort()
	cpu.sort()
	print("PROFILE renderer=%s CPU=%s frames=60 frame_min_ms=%.3f frame_median_ms=%.3f frame_p95_ms=%.3f cpu_median_ms=%.3f cpu_p95_ms=%.3f fps=%d" % [DisplayServer.get_name(),OS.get_processor_name(),elapsed[0],elapsed[30],elapsed[57],cpu[30],cpu[57],Engine.get_frames_per_second()])
	check(elapsed[57] < 250,"performance has no critical quarter-second stalls")
	if DisplayServer.get_name() != "headless" and OS.get_cmdline_user_args().has("--capture-profile"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/m5-load.png")
	run.queue_free()
	await process_frame
	await process_frame
	check(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) <= baseline+3,"run teardown returns live node count to baseline")
	print("RESULT performance: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
