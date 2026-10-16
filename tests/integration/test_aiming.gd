extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS ",label)
	else:
		failures += 1
		printerr("FAIL ",label)
func run_tests() -> void:
	var source := (load("res://scenes/characters/player.tscn") as PackedScene).instantiate() as PlayerActor
	source.actor_id = 1
	root.add_child(source)
	source.position = Vector2(250,300)
	source.set_physics_process(false)
	source.stats.crit_chance = 0
	var target := (load("res://scenes/enemies/chaser.tscn") as PackedScene).instantiate() as EnemyActor
	target.actor_id = 2
	root.add_child(target)
	target.set_physics_process(false)
	target.stats.armor = 0
	var combat := CombatService.new()
	combat.rng = RunRng.new(13).stream(&"combat")
	root.add_child(combat)
	combat.actor_provider = func() -> Array[Actor]: return [source,target]
	for name in ["astra","vex"]:
		target.position = Vector2(450,300)
		target.velocity = Vector2(0,80)
		var skill := load("res://content/skills/%s_basic.tres" % name) as SkillDefinition
		var runtime := SkillRuntime.new(skill,1)
		runtime.unlock_for_level(1)
		var context := combat.next_context(source,skill.id)
		context.runtime = runtime
		var hp: float = target.health.current
		check(skill.executor.execute(combat,source,target,skill.rank_scaling[0],context),name+" basic emits projectile")
		var projectile := combat.get_child(0) as CombatProjectile
		var initial: Vector2 = projectile._direction
		check(projectile._steering == 0,name+" basic has no implicit homing")
		check(initial.y > 0,name+" aims ahead of moving target")
		var straight: bool = true
		for i in range(40):
			target.position += target.velocity / 60.0
			await physics_frame
			if is_instance_valid(projectile) and not projectile.is_queued_for_deletion():
				straight = straight and projectile._direction.is_equal_approx(initial)
		check(straight,name+" trajectory remains straight")
		check(target.health.current < hp,name+" actually hits moving target")
		combat.clear_transients()
		await process_frame
	var extra := Actor.new()
	extra.team = 2
	extra.actor_id = 3
	extra.stats_definition = ActorStatDefinition.new()
	root.add_child(extra)
	extra.position = Vector2(1000,350)
	combat.actor_provider = func() -> Array[Actor]: return [source,target,extra]
	var guided := CombatProjectile.new()
	var guided_rank := SkillRankDefinition.new()
	guided_rank.range_px = 500
	guided_rank.projectile_speed = 100
	guided.configure_direction(combat,source,target,guided_rank,combat.next_context(source,&"fixture.guided"),Vector2.RIGHT,.5,null)
	combat.add_child(guided)
	guided.set_physics_process(false)
	guided.position = Vector2(1000,300)
	guided._hits[target.actor_id] = true
	guided._physics_process(.01)
	check(guided._target.get_ref() == extra,"homing reacquires from projectile and excludes already-hit target")
	check(guided._direction.y > 0,"explicit homing still turns toward fresh target")
	combat.clear_transients()
	extra.queue_free()
	await process_frame
	combat.actor_provider = func() -> Array[Actor]: return [source,target]
	var profile := load("res://content/characters/astra_loadout.tres") as CombatLoadoutDefinition
	if profile == null:
		printerr("FAIL missing profile")
		quit(1)
		return
	var controller := SkillController.new(1,profile.active_skills)
	controller.bind(source,combat)
	controller.sync_level(3)
	controller.set_mode(&"MANUAL")
	controller.candidates = [target]
	source.manual_aim = true
	source.set_physics_process(true)
	Input.action_press(&"move_down")
	for i in range(3): await physics_frame
	Input.action_release(&"move_down")
	for i in range(3): await physics_frame
	source.set_physics_process(false)
	check(source.facing.is_equal_approx(Vector2.DOWN),"Manual facing follows movement and persists after stopping")
	check(controller.request_cast(1,source.position+Vector2.UP*200),"manual cast succeeds away from enemy")
	var shot := combat.get_child(0) as CombatProjectile
	check(source.facing.is_equal_approx(Vector2.DOWN) and shot._direction.is_equal_approx(source.facing),"Manual cast ignores opposite mouse aim and follows facing")
	var saved: Vector2 = source.facing
	source.face_toward(source.position)
	check(source.facing == saved,"cursor at feet preserves last facing")
	if DisplayServer.get_name() != "headless":
		source.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/manual-facing.png")
	combat.queue_free()
	source.queue_free()
	target.queue_free()
	await process_frame
	print("RESULT aiming checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
