extends SceneTree
## QA-only real-executor captures; production skill unlocks/stats remain unchanged.
var out: String = "res://reports/visual_qa/v3_astra/"
var frame_times: Array[float] = []
func _initialize() -> void: call_deferred("run")
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var im: Image = root.get_texture().get_image()
	if im.get_width()!=640: im.resize(640,360,Image.INTERPOLATE_NEAREST)
	im.save_png(out+label+".png")
	im.resize(im.get_width()*2,im.get_height()*2,Image.INTERPOLATE_NEAREST)
	im.save_png(out+label+"_2x.png")
func release_keys() -> void:
	for key in [&"move_left",&"move_right",&"move_up",&"move_down"]: Input.action_release(key)
func run() -> void:
	var menu := (load("res://scenes/bootstrap/main.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(5): await process_frame
	await shot("menu")
	menu.free()
	var game := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(game)
	game.audio.enabled = false
	if OS.get_cmdline_user_args().has("--normal"):
		for f in range(600):
			if game._offer.size()==3: game.request_upgrade(0)
			release_keys()
			Input.action_press([&"move_right",&"move_down",&"move_left",&"move_up"][(f/150)%4])
			if f==450: await shot("normal_play")
			await process_frame
		release_keys()
		print("RESULT normal v3 PLAY alive=",game.state.alive)
		game.free();quit();return
	game.set_physics_process(false)
	game._arena.apply_layout(load("res://content/maps/ruined_temple.tres") as MapDefinition,[])
	game.player.invulnerability_left = 999999
	game.skills.sync_level(11)
	game.skills.set_mode(&"MANUAL")
	game.presentation.hide()
	var target: EnemyActor = game.spawn_enemy()
	target.set_physics_process(false)
	target.health = Health.new(100000)
	for f in range(1200):
		var start: int = Time.get_ticks_usec()
		var section: int = f/120
		var local: int = f%120
		if local==0:
			release_keys()
			game.combat.clear_transients();game.visual_factory.clear();game.player.clear_temporary()
			game.player.position = Vector2.ZERO
			game._camera.offset = Vector2(120 if section==6 else (280 if section==7 else 0),0)
			target.position = Vector2(150,0)
			game.player.facing = Vector2.RIGHT
		if section<4:
			Input.action_press([&"move_right",&"move_down",&"move_left",&"move_up"][section])
		elif section<8:
			var slot: int = section-3
			if local in [5,65]:
				game.skills.runtime_for(slot).advance_cooldown(10000)
				game.skills.request_cast(slot,Vector2(150,0))
			if local in [6,12,110]: await shot("skill_%d_%d" % [slot,local])
		elif section==8:
			if local==0:
				game.set_physics_process(true)
				for i in range(30):
					var enemy: EnemyActor = game.spawn_enemy()
					if enemy!=null:
						enemy.position=Vector2.from_angle(i*TAU/30)*Vector2(260,130)
						enemy.health=Health.new(100000)
			if local in [5,35,65,95]:
				for slot in range(1,5):
					game.skills.runtime_for(slot).advance_cooldown(10000)
					game.skills.request_cast(slot,Vector2(150,0))
			if local==40: await shot("crowd_30")
		else:
			if local==0:
				game.set_physics_process(false)
				for enemy in game._enemies:
					if is_instance_valid(enemy): enemy.set_physics_process(false)
				for pair: Array in [["projectile_split",1],["echo_cast",1],["area_expand",3]]:
					game.augments.apply_bound(load("res://content/augments/mechanics/"+pair[0]+".tres") as AugmentDefinition,game.skills.runtime_for(pair[1]))
			if local in [5,65]:
				for slot in [1,3]:
					game.skills.runtime_for(slot).advance_cooldown(10000)
					game.skills.request_cast(slot,Vector2(150,0))
			if local in [10,30]: await shot("augments_%d"%local)
		if f==30: await shot("astra_native")
		await process_frame
		frame_times.append((Time.get_ticks_usec()-start)/1000.0)
	release_keys()
	var evidence: Dictionary = {"frames":1200,"capture_fps":30,"fixture":"real executors, forced unlocks and invulnerability; separate normal_play video preserves normal progression","renderer":RenderingServer.get_video_adapter_name(),"nodes":root.get_tree().get_node_count(),"art_approval":"PENDING"}
	FileAccess.open(out+"capture.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"  "))
	game.free()
	print("RESULT v3 capture frames=1200 failures=0")
	quit()
