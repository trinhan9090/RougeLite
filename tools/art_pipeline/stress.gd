extends SceneTree
## Explicit test-only populations above production cap110; no balance edits.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var failed: int = 0
	for population in [100,200,400]:
		var game := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
		root.add_child(game)
		game._spawn_clock = 99999
		game._basic.cooldown_left = 99999
		game.player.invulnerability_left = 99999
		game.audio.enabled = false
		game._arena.apply_layout(game._arena.definition,[])
		for index in range(population):
			var enemy := (load("res://scenes/enemies/chaser.tscn") as PackedScene).instantiate() as EnemyActor
			enemy.actor_id = index+2
			enemy.position = Vector2.from_angle(index*2.399963)*float(300+(index%12)*30)
			game._actors.add_child(enemy)
			enemy.set_target(game.player)
			enemy.navigation = game._arena.navigation_direction
			game._enemies.append(enemy)
			game._enemy_attacks[enemy.actor_id] = AttackController.new(enemy,load("res://content/skills/enemy_chaser_basic.tres") as SkillDefinition)
		var rank := SkillRankDefinition.new()
		rank.damage = 0
		rank.range_px = 5000
		rank.projectile_speed = 20
		for group in range(5):
			var intent := CastIntent.new()
			intent.source_ref = weakref(game.player)
			intent.rank = rank
			intent.context = game.combat.next_context(game.player,&"skill.astra.basic")
			for index in range(60):
				game.combat.emit_projectile(intent,Vector2.RIGHT.rotated(index*.01),1,null)
				(game.combat.get_child(game.combat.get_child_count()-1) as Node2D).global_position = Vector2(-850,-650)
		for index in range(20):
			var orb := XpOrb.new()
			orb.configure(game.player,1,game._curve)
			game._loot.add_child(orb)
			orb.position = Vector2.from_angle(index*TAU/20)*220
			orb.set_physics_process(false) # Hold visible loot without upgrade pause in a timed fixture.
		game._camera.zoom = Vector2.ONE*.5
		var timings: Array[float] = []
		var last: int = Time.get_ticks_usec()
		for frame in range(60):
			await process_frame
			var now: int = Time.get_ticks_usec()
			timings.append((now-last)/1000.0)
			last = now
		if game._enemies.size()!=population or game.combat.get_child_count()!=300: failed += 1
		if game.visual_factory.trails > 120 or game.visual_factory.get_child_count()>80: failed += 1
		timings.sort()
		print("ART_STRESS population=%d projectiles=%d frames=60 median_ms=%.3f p95_ms=%.3f trails=%d impacts=%d renderer=%s cpu=%s" % [population,game.combat.get_child_count(),timings[30],timings[57],game.visual_factory.trails,game.visual_factory.get_child_count(),DisplayServer.get_name(),OS.get_processor_name()])
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://screenshots/art/stress_%d.png" % population)
		game.free()
		await process_frame
	print("RESULT art stress failures=%d (performance acceptance reported separately)" % failed)
	quit(0 if failed==0 else 1)
