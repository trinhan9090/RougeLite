extends SceneTree
var checks: int = 0
var failures: int = 0
var actors: Array[Actor] = []

func _initialize() -> void: call_deferred("run_tests")
func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS ", label)
	else:
		failures += 1
		printerr("FAIL ", label)
func frames(count: int) -> void:
	for index in range(count): await physics_frame
func make_actor(id: int, team_id: int, point: Vector2) -> Actor:
	var actor := Actor.new()
	actor.actor_id = id
	actor.team = team_id
	actor.position = point
	actor.stats_definition = ActorStatDefinition.new()
	actor.collision_layer = 1 if team_id == 1 else 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18
	shape.shape = circle
	actor.add_child(shape)
	root.add_child(actor)
	actor.stats.armor = 0
	actor.stats.crit_chance = 0
	actor.health.maximum = 10000
	actor.health.current = 10000
	actors.append(actor)
	return actor
func runtime(path: String) -> SkillRuntime:
	var result := SkillRuntime.new(load("res://content/skills/%s.tres" % path) as SkillDefinition, 1)
	result.unlock_for_level(11)
	return result
func bind(manager: AugmentManager, name: String, skill: SkillRuntime) -> void:
	var definition := load("res://content/augments/mechanics/%s.tres" % name) as AugmentDefinition
	for rank in range(5): assert(manager.apply_bound(definition, skill))
func cast(combat: CombatService, source: Actor, target: Actor, skill: SkillRuntime, manager: AugmentManager) -> CastIntent:
	var result := CastIntent.new()
	result.source_ref = weakref(source)
	result.target_ref = weakref(target)
	result.rank = skill.effective_rank()
	result.rank.behavior = null
	result.runtime = skill
	result.context = combat.next_context(source, skill.definition.id)
	result.context.runtime = skill
	result.context.manager = manager
	result.direction = Vector2.RIGHT
	result.aim_point = target.position
	return result
func snapshot(combat: CombatService, root_id: int) -> Array[String]:
	var result: Array[String] = []
	for child in combat.get_children():
		if child is CombatProjectile and child._context.root_cast_id == root_id:
			result.append("%.6f/%.6f/%s" % [child._direction.angle(), child._rank.damage, child._context.source_augment_id])
	return result

func run_tests() -> void:
	var source: Actor = make_actor(1, 1, Vector2.ZERO)
	var target: Actor = make_actor(2, 2, Vector2(130, 0))
	var other: Actor = make_actor(3, 2, Vector2(160, 25))
	var combat := CombatService.new()
	combat.actor_provider = func() -> Array[Actor]: return actors
	combat.rng = RunRng.new(42).stream(&"combat")
	root.add_child(combat)
	await frames(2)
	for path in ["astra_j", "vex_l"]:
		var skill: SkillRuntime = runtime(path)
		var manager := AugmentManager.new()
		for name in ["projectile_split", "multishot", "echo_cast", "explosion_on_hit"]: bind(manager, name, skill)
		var intent: CastIntent = cast(combat, source, target, skill, manager)
		check(skill.definition.executor.execute_cast(intent, combat) and skill.commit_cast(), "%s four-way cast accepted" % path)
		check(intent.context.budget.projectiles == 42, "%s multishot6 lanes then split6 each=42" % path)
		var cooldown: float = skill.cooldown_remaining
		await frames(40)
		check(intent.context.budget.projectiles == 48 and skill.cooldown_remaining == cooldown, "%s exactly one echo adds6 shots without cooldown charge" % path)
		await frames(70)
		check(intent.context.budget.procs <= 32 and intent.context.budget.deepest <= 3 and intent.context.budget.projectiles <= 64, "%s combined budgets bounded" % path)
		check(combat.get_child_count() == 0 and combat._queue.is_empty(), "%s combined projectiles and proc queue settle" % path)
		check(target.health.current < 10000 and other.health.current < 10000, "%s combined effects resolve actual hits" % path)
	# Acquisition order cannot change generated geometry or damage.
	var skill: SkillRuntime = runtime("astra_j")
	var forward := AugmentManager.new()
	var reverse := AugmentManager.new()
	for name in ["projectile_split", "multishot", "pierce", "execute"]: bind(forward, name, skill)
	for name in ["execute", "pierce", "multishot", "projectile_split"]: bind(reverse, name, skill)
	var a: CastIntent = cast(combat, source, target, skill, forward)
	var b: CastIntent = cast(combat, source, target, skill, reverse)
	skill.definition.executor.execute_cast(a, combat)
	skill.definition.executor.execute_cast(b, combat)
	check(snapshot(combat, a.context.root_cast_id) == snapshot(combat, b.context.root_cast_id), "modifier order independent of acquisition order")
	await frames(70)
	# Adversarial base pattern truncates the final generated shots at64.
	var overflow: CastIntent = cast(combat, source, target, skill, forward)
	overflow.rank.projectile_count = 100
	skill.definition.executor.execute_cast(overflow, combat)
	check(overflow.context.budget.projectiles == 64 and snapshot(combat, overflow.context.root_cast_id).size() == 64, "overflow deterministically truncates to64 root projectiles")
	await frames(80)
	check(combat.get_child_count() == 0, "overflow has finite lifetime")
	# Homing turns an actual projectile toward the target on two compatible kits.
	for path in ["astra_j", "vex_l"]:
		var homing_skill: SkillRuntime = runtime(path)
		var manager := AugmentManager.new()
		bind(manager, "homing", homing_skill)
		target.position = Vector2(300, 150)
		var intent: CastIntent = cast(combat, source, target, homing_skill, manager)
		homing_skill.definition.executor.execute_cast(intent, combat)
		await frames(4)
		var projectile := combat.get_child(0) as CombatProjectile
		check(projectile != null and projectile._direction.y > 0 and projectile._direction.angle() <= PI / 2, "%s homing steers actual projectile" % path)
		await frames(70)
	target.position = Vector2(130, 0)
	# Refund consumes one roll per root, deterministic over seeded sequence.
	for path in ["astra_j", "vex_l"]:
		var refund_skill: SkillRuntime = runtime(path)
		var manager := AugmentManager.new()
		bind(manager, "cooldown_refund", refund_skill)
		var refunds: int = 0
		var expected: int = 0
		var seed_stream := RandomNumberGenerator.new()
		seed_stream.seed = 99
		combat.rng.seed = 99
		for trial in range(50):
			refund_skill.advance_cooldown(100)
			refund_skill.commit_cast()
			var intent: CastIntent = cast(combat, source, target, refund_skill, manager)
			intent.rank.damage = 0
			seed_stream.randf() # Isolated universal fixture allows critical roll.
			var expected_refund: bool = seed_stream.randf() < .16
			if expected_refund: expected += 1
			seed_stream.randf() # Second hit critical roll; refund deduped.
			combat.hit(source, target, intent.rank, intent.context)
			combat.hit(source, target, intent.rank, intent.context)
			await frames(3)
			check((refund_skill.cooldown_remaining < refund_skill.effective_rank().cooldown) == expected_refund, "%s refund matches seeded roll trial%d" % [path,trial])
			if refund_skill.cooldown_remaining < refund_skill.effective_rank().cooldown:
				refunds += 1
				check(is_equal_approx(refund_skill.cooldown_remaining, refund_skill.effective_rank().cooldown * .9), "%s refund exact10percent base" % path)
		check(refunds == expected and refunds > 0 and refunds < 50, "%s refund seeded16percent; one roll per root" % path)
	# The four-way combination must not duplicate kill events when many lanes overlap.
	var kill_ids: Dictionary[int, int] = {}
	combat.resolver.events.actor_killed.connect(func(_context: CombatContext, result: DamageResult) -> void: kill_ids[result.target_id] = kill_ids.get(result.target_id, 0) + 1)
	target.health.current = 20
	other.health.current = 20
	target.position = Vector2(100, 0)
	other.position = Vector2(120, 0)
	var lethal_manager := AugmentManager.new()
	var lethal_skill: SkillRuntime = runtime("vex_l")
	for name in ["projectile_split", "multishot", "echo_cast", "explosion_on_hit"]: bind(lethal_manager, name, lethal_skill)
	var lethal: CastIntent = cast(combat, source, target, lethal_skill, lethal_manager)
	lethal_skill.definition.executor.execute_cast(lethal, combat)
	await frames(110)
	check(kill_ids.size() == 2 and kill_ids.get(2) == 1 and kill_ids.get(3) == 1, "four-way overlap emits exactly one kill per target")
	check(combat._queue.is_empty() and combat.get_child_count() == 0, "four-way lethal combo settles after targets die")
	combat.queue_free()
	for value in actors: value.queue_free()
	await process_frame
	print("RESULT augment combinations: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
