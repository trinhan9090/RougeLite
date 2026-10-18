extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(game)
	game.audio.enabled=false
	game.player.invulnerability_left=10000
	game.skills.sync_level(11)
	for i in range(30):
		var enemy: EnemyActor=game.spawn_enemy()
		if enemy!=null:
			enemy.position=Vector2.from_angle(i*TAU/30)*Vector2(240,130)
			enemy.health=Health.new(100000)
	var times: Array[float]=[]
	var max_nodes: int=0
	var max_effects: int=0
	for f in range(720):
		if f%60==0:
			for slot in range(1,5):
				game.skills.runtime_for(slot).advance_cooldown(10000)
				game.skills.request_cast(slot,game.player.position+Vector2(150,0))
		var start: int=Time.get_ticks_usec()
		await process_frame
		if f>=120: times.append((Time.get_ticks_usec()-start)/1000.0)
		max_nodes=maxi(max_nodes,get_node_count())
		max_effects=maxi(max_effects,game.visual_factory.get_child_count())
	times.sort()
	var total: float=0
	for value in times: total+=value
	var data: Dictionary={"cpu":OS.get_processor_name(),"gpu":RenderingServer.get_video_adapter_name(),"renderer":"gl_compatibility","samples":times.size(),"enemies":game._enemies.size(),"skill_cycles":12,"mean_ms":total/times.size(),"median_ms":times[times.size()/2],"p95_ms":times[int(times.size()*.95)],"one_percent_low_fps":1000/maxf(.001,times[int(times.size()*.99)]),"mean_fps":1000/(total/times.size()),"max_nodes":max_nodes,"max_temporary_vfx":max_effects,"fixture":"real live AI/combat; QA-only invulnerability, high enemy HP and forced cooldowns; no movie writer"}
	FileAccess.open("res://reports/visual_qa/v3_astra/performance.json",FileAccess.WRITE).store_string(JSON.stringify(data,"  "))
	game.free()
	print("RESULT performance measurement completed failures=0")
	quit()
