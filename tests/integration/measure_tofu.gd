extends SceneTree
var frames_ms: Array[float]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var settings:=root.get_node("AppSettings") as SettingsService;var old: StringName=settings.mode();settings.set_mode(&"MANUAL")
	var game: CombatRunRoot=(load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate();game.loadout_id=&"loadout.tofu";root.add_child(game)
	game.skills.sync_level(11);game.player.invulnerability_left=30
	var mobs: Array[EnemyActor]=[];var safe: bool=true
	for i in range(30):
		var mob: EnemyActor=game.spawn_enemy()
		if mob!=null:
			safe=safe and mob.global_position.distance_to(game.player.global_position)>=550
			mob.health=TrainingHealth.new(100000);mobs.append(mob)
	# QA-only dense placement after validating real safe spawning, to stress actual melee/VFX.
	for i in range(mobs.size()):mobs[i].position=game.player.position+Vector2.from_angle(i*TAU/30)*(100+(i%3)*50)
	var start: int=Time.get_ticks_usec();var previous: int=start;var cast_at: float=0;var cast_index: int=0;var casts: Dictionary={}
	while Time.get_ticks_usec()-start<8000000:
		await process_frame
		var now: int=Time.get_ticks_usec();frames_ms.append((now-previous)/1000.0);previous=now
		var seconds: float=(now-start)/1000000.0
		if seconds>=cast_at:
			game.skills.advance_cooldowns(1000)
			var slot: int=cast_index%4+1
			if game.skills.request_cast(slot,game.player.position+Vector2.RIGHT*100):casts[str(slot)]=int(casts.get(str(slot),0))+1
			cast_index+=1
			cast_at+=1
	var elapsed: float=(Time.get_ticks_usec()-start)/1000000.0
	frames_ms.sort()
	var result: Dictionary={"seconds":elapsed,"accepted_casts_by_slot":casts,"mobs":mobs.size(),"safe_initial_spawns":safe,"samples":frames_ms.size(),"median_ms":frames_ms[int(frames_ms.size()/2)],"p95_ms":frames_ms[int(frames_ms.size()*.95)],"max_ms":frames_ms.back(),"viewport":game.get_viewport().get_visible_rect().size,"renderer":RenderingServer.get_video_adapter_name(),"note":"8s actual GUI dense QA fixture, not stable60FPS certification; other regression processes may run concurrently"}
	var file:=FileAccess.open("res://reports/tofu/20261018/fps_metrics.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
	print("TOFU_PERF ",JSON.stringify(result))
	game.combat.clear_transients();await process_frame
	game.queue_free();await process_frame;settings.set_mode(old)
	print("RESULT tofu stress: checks=2 failures=",0 if safe and mobs.size()==30 else 1);quit(0 if safe and mobs.size()==30 else 1)
