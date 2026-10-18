extends SceneTree
func _initialize() -> void:call_deferred("run_measurement")
func run_measurement() -> void:
	var settings:=root.get_node("AppSettings") as SettingsService
	var old: StringName=settings.mode();settings.set_mode(&"MANUAL")
	var game: CombatRunRoot=(load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate()
	game.loadout_id=&"loadout.viridian";root.add_child(game)
	game.player.invulnerability_left=10000
	game.skills.sync_level(11)
	for slot in range(1,5):
		while game.skills.upgrade_rank(slot):continue
	var safe: bool=true
	for index in range(30):
		var enemy: EnemyActor=game.spawn_enemy()
		if enemy==null:printerr("FAIL fixture cannot spawn30 enemies");quit(1);return
		safe=safe and enemy.position.distance_to(game.player.position)>=550
		# QA-only reposition for visible combat load, after real safe spawn check.
		enemy.position=game.player.position+Vector2.from_angle(index*TAU/30)*Vector2(220,150)
		enemy.health=Health.new(100000)
	game.gate.request(10)
	for attempt in range(20):
		game._spawn_boss()
		if game.boss!=null:break
	if game.boss==null:printerr("FAIL real boss safe spawn");quit(1);return
	safe=safe and game.boss.position.distance_to(game.player.position)>=550
	game.boss.health=Health.new(100000)
	var samples: Array[float]=[]
	var max_nodes: int=0
	for frame in range(420):
		if frame%90==0:
			for slot in range(1,5):
				game.skills.runtime_for(slot).advance_cooldown(1000)
				game.skills.request_cast(slot,game.player.position+Vector2.RIGHT*330)
		var start: int=Time.get_ticks_usec()
		await process_frame
		if frame>=60:samples.append((Time.get_ticks_usec()-start)/1000.0)
		max_nodes=maxi(max_nodes,get_node_count())
	samples.sort()
	var report: Dictionary={"cpu":OS.get_processor_name(),"gpu":RenderingServer.get_video_adapter_name(),"renderer":"gl_compatibility","viewport":get_root().size,"samples":samples.size(),"enemies_including_boss":game._enemies.size(),"safe_spawns_verified":safe,"median_ms":samples[samples.size()/2],"p95_ms":samples[int(samples.size()*.95)],"p99_ms":samples[int(samples.size()*.99)],"max_nodes":max_nodes,"boss_patterns_started":game.boss.attacks_started,"fixture":"Real AI/navigation/combat,30 QA high-HP mobs plus real boss; player QA invulnerability and forced skill cooldowns; no media capture."}
	FileAccess.open("res://reports/viridian/20261017/performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	var csv: String="percentile,milliseconds\np50,%f\np95,%f\np99,%f\n"%[report.median_ms,report.p95_ms,report.p99_ms]
	FileAccess.open("res://reports/viridian/20261017/fps_metrics.csv",FileAccess.WRITE).store_string(csv)
	game.free();await process_frame
	settings.set_mode(old)
	print("RESULT Viridian performance samples=%d failures=%d"%[samples.size(),0 if safe else 1])
	quit(0 if safe else 1)
