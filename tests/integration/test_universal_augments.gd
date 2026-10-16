extends SceneTree
var checks: int = 0
var failures: int = 0
var combat: CombatService
var source: Actor
var target: Actor
var other: Actor
var all_actors: Array[Actor] = []
var deaths: int = 0

func _initialize() -> void: call_deferred("run_tests")

func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS ", label)
	else:
		failures += 1
		printerr("FAIL ", label)

func frames(count: int) -> void:
	for index in range(count): await physics_frame

func actor(id: int, team_id: int, point: Vector2) -> Actor:
	var result := Actor.new()
	result.actor_id = id
	result.team = team_id
	result.position = point
	result.stats_definition = ActorStatDefinition.new()
	result.collision_layer = 1 if team_id == 1 else 2
	result.collision_mask = 4
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12
	shape.shape = circle
	result.add_child(shape)
	root.add_child(result)
	result.stats.crit_chance = 0
	result.stats.armor = 0
	result.health.maximum = 10000
	result.health.current = 10000
	all_actors.append(result)
	return result

func runtime(path: String) -> SkillRuntime:
	var value := SkillRuntime.new(load("res://content/skills/%s.tres" % path) as SkillDefinition, 1)
	value.unlock_for_level(11)
	return value

func augment(name: String) -> AugmentDefinition:
	return load("res://content/augments/mechanics/%s.tres" % name) as AugmentDefinition

func bind_max(manager: AugmentManager, name: String, skill: SkillRuntime) -> void:
	for index in range(5): check(manager.apply_bound(augment(name), skill), "%s rank %d binds" % [name, index + 1])

func intent(skill: SkillRuntime, manager: AugmentManager = null) -> CastIntent:
	var result := CastIntent.new()
	result.source_ref = weakref(source)
	result.target_ref = weakref(target)
	result.runtime = skill
	result.rank = skill.effective_rank()
	result.rank.behavior = null # Isolate universal modifiers from separately tested native kit graphs.
	result.direction = Vector2.RIGHT
	result.aim_point = target.position
	result.context = combat.next_context(source, skill.definition.id)
	result.context.manager = manager
	result.context.runtime = skill
	return result

func run_tests() -> void:
	source = actor(1, 1, Vector2.ZERO)
	target = actor(2, 2, Vector2(70, 0))
	other = actor(3, 2, Vector2(140, 0))
	target.died.connect(func(_actor: Actor) -> void: deaths += 1)
	combat = CombatService.new()
	combat.rng = RunRng.new(321).stream(&"combat")
	combat.actor_provider = func() -> Array[Actor]: return all_actors
	root.add_child(combat)
	await frames(2)
	# Every shared effect has two compatible real kit definitions and an incompatible one.
	var cases: Array = [
		["projectile_split","astra_j","vex_l","boros_j"], ["multishot","astra_j","vex_l","boros_j"],
		["pierce","astra_j","vex_l","boros_j"], ["homing","astra_j","vex_l","astra_i"],
		["echo_cast","astra_j","vex_l","astra_k"], ["area_expand","astra_l","boros_j","vex_l"],
		["explosion_on_hit","astra_j","vex_l","astra_k"], ["on_kill_burst","astra_j","vex_l","astra_k"],
		["cooldown_refund","astra_j","vex_l","boros_i"], ["shield_reflect","astra_k","boros_k","vex_l"],
		["dash_shockwave","vex_k","boros_l","astra_j"], ["execute","astra_j","boros_j","astra_k"]
	]
	for row: Array in cases:
		var manager := AugmentManager.new()
		check(manager.apply_bound(augment(row[0]), runtime(row[1])), "%s compatible %s" % [row[0],row[1]])
		check(manager.apply_bound(augment(row[0]), runtime(row[2])), "%s compatible %s" % [row[0],row[2]])
		check(not manager.apply_bound(augment(row[0]), runtime(row[3])), "%s rejects %s" % [row[0],row[3]])
	var mismatch := (load("res://content/skills/boros_j.tres") as SkillDefinition).duplicate(true) as SkillDefinition
	mismatch.declared_capabilities.append(&"spawn_projectile_pattern")
	check(not mismatch.validate().is_empty(), "capability tags cannot fabricate executor support")
	var shield: CastIntent = intent(runtime("astra_k"))
	check(shield.runtime.definition.executor.execute_cast(shield, combat) and source.health.shield_total() == 48, "self shield adapter adds exact shield")
	source.health.advance(4)
	check(source.health.shield_total() == 0, "self shield expires")
	var beam: CastIntent = intent(runtime("astra_i"))
	var before: float = target.health.current
	check(beam.runtime.definition.executor.execute_cast(beam, combat) and target.health.current == before - 120, "instant beam exact damage")
	var area_skill: SkillRuntime = runtime("astra_l")
	var area_manager := AugmentManager.new()
	bind_max(area_manager, "area_expand", area_skill)
	var area: CastIntent = intent(area_skill, area_manager)
	area.rank.duration = 0.1
	check(is_equal_approx(combat.modified_radius(area), 128), "area rank5 multiplies radius by1.6")
	before = target.health.current
	check(area_skill.definition.executor.execute_cast(area, combat), "ground area adapter accepted")
	await frames(10)
	check(target.health.current == before - 7, "ground area actual timed tick without damage inflation")
	var status_executor := EffectExecutorDefinition.new()
	status_executor.executor_id = &"executor.status_test"
	status_executor.kind = "status"
	status_executor.status = StatusEffectDefinition.new()
	check(status_executor.execute_cast(intent(runtime("astra_j")), combat) and target.statuses.movement_factor() == 0, "status adapter applies actual root")
	target.statuses.advance(3)
	# Real swept projectile pierces each collider once.
	var piercing: CastIntent = intent(runtime("vex_l"))
	before = target.health.current
	var other_before: float = other.health.current
	check(piercing.runtime.definition.executor.execute_cast(piercing, combat), "piercing projectile launched")
	await frames(50)
	check(target.health.current == before - 65 and other.health.current == other_before - 65, "swept piercing hits two unique targets once")
	# Split geometry and root counts on two kits share the same implementation.
	for path in ["astra_j", "vex_l"]:
		var skill: SkillRuntime = runtime(path)
		var manager := AugmentManager.new()
		bind_max(manager, "projectile_split", skill)
		var cast: CastIntent = intent(skill, manager)
		check(skill.definition.executor.execute_cast(cast, combat) and cast.context.budget.projectiles == 7, "%s rank5 split emits primary+6" % path)
		var damages: Array[float] = []
		for child in combat.get_children():
			if child is CombatProjectile and child._context.root_cast_id == cast.context.root_cast_id: damages.append(child._rank.damage)
		check(damages.size() == 7 and is_equal_approx(damages[1], cast.rank.damage * 0.65), "%s split secondary exact65percent" % path)
		check(not manager.apply_bound(augment("projectile_split"), skill), "rank6 split rejected")
	await frames(60)
	# Execute is evaluated once before normal defenses.
	var execution_skill: SkillRuntime = runtime("astra_j")
	var execution_manager := AugmentManager.new()
	bind_max(execution_manager, "execute", execution_skill)
	target.health.current = 100
	var execution: CastIntent = intent(execution_skill, execution_manager)
	combat.hit(source, target, execution.rank, execution.context)
	check(is_equal_approx(target.health.current, 100 - 36 * 1.3), "execute adds30percent once below25percentHP")
	# Explosion dedupes all primary hits to one root/target; secondary cannot chain.
	var proc_manager := AugmentManager.new()
	bind_max(proc_manager, "explosion_on_hit", execution_skill)
	var proc_cast: CastIntent = intent(execution_skill, proc_manager)
	target.health.current = 5000
	other.health.current = 5000
	combat.hit(source, target, proc_cast.rank, proc_cast.context)
	combat.hit(source, target, proc_cast.rank, proc_cast.context)
	check(proc_cast.context.budget.procs == 1, "explosion root/target dedupe")
	await frames(4)
	check(target.health.current == 5000 - 72 - 35 and other.health.current == 5000 - 35, "explosion exact primary and burst damage; no recursive chain")
	# Shield reflect absorbed damage only; reflected hits never bounce.
	var reflect_skill: SkillRuntime = runtime("boros_k")
	var reflect_manager := AugmentManager.new()
	bind_max(reflect_manager, "shield_reflect", reflect_skill)
	var reflect_cast: CastIntent = intent(reflect_skill, reflect_manager)
	reflect_skill.definition.executor.execute_cast(reflect_cast, combat)
	var incoming: CombatContext = combat.next_context(target, &"skill.enemy.fixture")
	var incoming_rank := SkillRankDefinition.new()
	incoming_rank.damage = 20
	incoming_rank.damage_type = "TRUE"
	before = target.health.current
	combat.hit(target, source, incoming_rank, incoming)
	await frames(3)
	check(target.health.current == before - 4 and source.health.shield_total() == 50 and incoming.budget.procs == 1, "reflect20percent absorbed; no recursive bounce")
	target.is_boss = true
	source.stats.damage_multiplier = 2
	source.stats.crit_chance = 1
	target.health.maximum = 100
	target.health.current = 100
	combat.hit(target, source, incoming_rank, combat.next_context(target, &"skill.enemy.fixture"))
	await frames(3)
	check(target.health.current == 99, "reflect boss cap1percent maximumHP even with damage/crit bonuses")
	source.stats.damage_multiplier = 1
	source.stats.crit_chance = 0
	target.is_boss = false
	target.health.maximum = 10000
	target.health.current = 5000
	# Dash movement happens over time, then one endpoint proc.
	var dash_skill: SkillRuntime = runtime("vex_k")
	var dash_manager := AugmentManager.new()
	bind_max(dash_manager, "dash_shockwave", dash_skill)
	var dash: CastIntent = intent(dash_skill, dash_manager)
	before = other.health.current
	check(dash_skill.definition.executor.execute_cast(dash, combat), "dash adapter accepted")
	await frames(25)
	check(is_equal_approx(source.position.x, 190) and not source.motion_active and dash.context.budget.procs == 1 and other.health.current == before - 65, "dash endpoint one shockwave exact65physical")
	source.position = Vector2.ZERO
	# Kill burst uses accepted primary kill once, never duplicate death.
	var kill_skill: SkillRuntime = runtime("astra_j")
	var kill_manager := AugmentManager.new()
	bind_max(kill_manager, "on_kill_burst", kill_skill)
	var kill_cast: CastIntent = intent(kill_skill, kill_manager)
	target.health.current = 10
	other.position = Vector2(100, 0)
	before = other.health.current
	combat.hit(source, target, kill_cast.rank, kill_cast.context)
	combat.hit(source, target, kill_cast.rank, kill_cast.context)
	await frames(4)
	check(deaths == 1 and other.health.current == before - 40 and kill_cast.context.budget.procs == 1, "kill burst primary death once and exact40damage")
	# Explicit budget adversary including arbitrary child recursion.
	var envelope: CombatContext = combat.next_context(source, &"skill.budget")
	var child: CombatContext = envelope
	for depth in range(3): child = child.child(&"fixture")
	check(child != null and child.child(&"fixture") == null and envelope.budget.deepest == 3, "shared depth capped3")
	for index in range(100): envelope.child(&"fixture")
	check(envelope.budget.procs == 32, "shared proc budget capped32 across branches")
	for index in range(100): envelope.budget.spend_projectile()
	check(envelope.budget.projectiles == 64, "shared projectile budget capped64")
	combat.queue_free()
	for value in all_actors: value.queue_free()
	await process_frame
	print("RESULT universal augments: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
