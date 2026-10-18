extends SceneTree
## Real wall-clock600second soak, no recording. QA caps affect only detached fixture config.
func _initialize() -> void:call_deferred("run_soak")
func run_soak() -> void:
	var settings:=root.get_node("AppSettings") as SettingsService
	var old: StringName=settings.mode();settings.set_mode(&"AUTO")
	var game: CombatRunRoot=(load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate()
	game.loadout_id=&"loadout.graveshade";root.add_child(game)
	game.set_process_unhandled_input(false);game.player.set_physics_process(false)
	game.player.health=TrainingHealth.new(115)
	game.skills.sync_level(11)
	for slot in range(1,5):
		while game.skills.upgrade_rank(slot):continue
	game._spawn_clock=1000000
	game._spawn_config.max_enemies=120;game._spawn_config.initial_enemy_cap=120
	var start: int=Time.get_ticks_msec()
	var last: int=Time.get_ticks_usec()
	var next_cast: float=0
	var phase: int=-1
	var samples: Array[float]=[]
	var phases: Array[Dictionary]=[]
	var max_nodes: int=0
	var max_mines: int=0
	var max_voices: int=0
	var safe: bool=true
	var failed: bool=false
	var duration: float=600
	if OS.get_cmdline_user_args().has("--quick-probe"):duration=12
	while (Time.get_ticks_msec()-start)/1000.0<duration:
		var seconds: float=(Time.get_ticks_msec()-start)/1000.0
		var current: int=mini(2,int(seconds/(duration/3)))
		if current!=phase:
			if not samples.is_empty():phases.append(metrics(phase,samples));samples.clear()
			phase=current
			var wanted: int=[30,60,120][phase]
			var attempts: int=0
			while game._enemies.size()<wanted and attempts<500:
				attempts+=1
				var enemy: EnemyActor=game.spawn_enemy()
				if enemy==null:continue
				safe=safe and enemy.global_position.distance_to(game.player.global_position)>=550
				var index: int=game._enemies.size()
				enemy.position=game.player.position+Vector2.from_angle(index*2.39996)*lerpf(130,330,float(index%11)/10)
				enemy.health=TrainingHealth.new(100000)
			if game._enemies.size()!=wanted:failed=true;printerr("FAIL stress spawn fixture ",game._enemies.size(),"/",wanted)
			print("SOAK_PHASE mobs=",game._enemies.size()," seconds=",seconds)
		if seconds>=next_cast:
			next_cast=seconds+4
			for slot in range(1,5):game.skills.runtime_for(slot).advance_cooldown(1000);game.skills.request_cast(slot)
		await process_frame
		var now: int=Time.get_ticks_usec();samples.append((now-last)/1000.0);last=now
		max_nodes=maxi(max_nodes,get_node_count())
		var mines: int=0
		for child in game.combat.get_children():
			if child is TacticalMine:mines+=1
		max_mines=maxi(max_mines,mines)
		var voices: int=0
		for voice in game.player.action_audio.voices:
			if voice.playing:voices+=1
		max_voices=maxi(max_voices,voices)
		if not game.player.health.is_alive() or game.state.run_phase!=&"RUNNING":failed=true;printerr("FAIL soak phase=",game.state.run_phase," alive=",game.player.health.is_alive());break
	if not samples.is_empty():phases.append(metrics(phase,samples))
	var report: Dictionary={"wall_seconds":(Time.get_ticks_msec()-start)/1000.0,"required_seconds":duration,"real_gameplay_events":game.combat.event_count,"mobs":game._enemies.size(),"safe_spawns":safe,"phases":phases,"max_nodes":max_nodes,"max_mines":max_mines,"max_audio_voices":max_voices,"renderer":DisplayServer.get_name(),"gpu":RenderingServer.get_video_adapter_name(),"cpu":OS.get_processor_name(),"memory_static":OS.get_static_memory_usage(),"qa_only":"Detached spawn cap120, immortal player and enemies, forced4second skills; real AI/navigation/projectiles/damage/render/audio. NormalPLAY cap110 unchanged.","final_run_phase":String(game.state.run_phase),"failures":1 if failed or not safe or max_mines>6 else 0}
	var path: String="res://reports/graveshade/soak_quick.json" if duration<600 else "res://reports/graveshade/soak600.json"
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	game.free();await process_frame;settings.set_mode(old)
	print("RESULT graveshade_soak: seconds=",report.wall_seconds," failures=",report.failures)
	quit(report.failures)
func metrics(phase: int,samples: Array[float]) -> Dictionary:
	samples.sort()
	return {"mobs":[30,60,120][phase],"samples":samples.size(),"median_ms":samples[samples.size()/2],"p95_ms":samples[mini(samples.size()-1,int(samples.size()*.95))],"p99_ms":samples[mini(samples.size()-1,int(samples.size()*.99))]}
