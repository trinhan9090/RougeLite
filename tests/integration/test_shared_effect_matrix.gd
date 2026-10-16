extends SceneTree
## Behavioral coverage for the second compatible kit of every shared operation.
var checks: int = 0
var failures: int = 0
var source: Actor
var target: Actor
var combat: CombatService
var damage_events: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS ", label)
	else:
		failures += 1
		printerr("FAIL ", label)
func frames(count: int) -> void:
	for index in range(count): await physics_frame
func make_actor(id: int, team_id: int) -> Actor:
	var result := Actor.new()
	result.actor_id = id
	result.team = team_id
	result.stats_definition = ActorStatDefinition.new()
	root.add_child(result)
	result.stats.armor = 0
	result.stats.crit_chance = 0
	return result
func prepare(path: String, name: String) -> CastIntent:
	source.position = Vector2.ZERO
	target.position = Vector2(50, 0)
	source.health = Health.new(10000)
	target.health = Health.new(10000)
	damage_events.clear()
	var runtime := SkillRuntime.new(load("res://content/skills/%s.tres" % path) as SkillDefinition, 1)
	runtime.unlock_for_level(11)
	var manager := AugmentManager.new()
	assert(manager.apply_bound(load("res://content/augments/mechanics/%s.tres" % name) as AugmentDefinition, runtime))
	var result := CastIntent.new()
	result.source_ref = weakref(source)
	result.target_ref = weakref(target)
	result.runtime = runtime
	result.rank = runtime.effective_rank()
	result.rank.behavior = null
	result.context = combat.next_context(source, runtime.definition.id)
	result.context.manager = manager
	result.context.runtime = runtime
	result.direction = Vector2.RIGHT
	result.aim_point = target.position
	return result
func run_tests() -> void:
	source = make_actor(1,1)
	target = make_actor(2,2)
	combat = CombatService.new()
	combat.rng = RunRng.new(29).stream(&"combat")
	combat.actor_provider = func() -> Array[Actor]: return [source,target]
	combat.resolver.events.damage_applied.connect(func(context: CombatContext, result: DamageResult) -> void: damage_events.append({"operation":context.source_augment_id,"damage":result.mitigated_damage}))
	root.add_child(combat)
	for path in ["astra_l", "boros_j"]:
		var intent: CastIntent = prepare(path,"area_expand")
		intent.rank.duration = .01
		intent.aim_point = Vector2.ZERO
		target.position = Vector2(intent.rank.radius_px * 1.1, 0)
		intent.runtime.definition.executor.execute_cast(intent,combat)
		await frames(3)
		check(target.health.current == 10000 - intent.rank.damage, "%s expanded collision reaches beyond base radius" % path)
	for path in ["astra_k", "boros_k"]:
		var intent: CastIntent = prepare(path,"shield_reflect")
		intent.runtime.definition.executor.execute_cast(intent,combat)
		var rank := SkillRankDefinition.new()
		rank.damage = 20
		rank.damage_type = "TRUE"
		combat.hit(target,source,rank,combat.next_context(target,&"skill.fixture"))
		await frames(3)
		check(is_equal_approx(target.health.current,10000 - 20 * .08) and is_equal_approx(source.health.shield_total(),intent.rank.shield - 20), "%s reflect uses absorbed damage" % path)
	for path in ["vex_k", "boros_l"]:
		var intent: CastIntent = prepare(path,"dash_shockwave")
		target.position = Vector2(intent.rank.range_px + 20,0)
		intent.runtime.definition.executor.execute_cast(intent,combat)
		await frames(25)
		var waves: Array[Dictionary] = damage_events.filter(func(event: Dictionary) -> bool: return event.operation == &"dash_wave")
		check(waves.size() == 1 and waves[0].damage == 25 and is_equal_approx(source.position.x,intent.rank.range_px), "%s one25damage endpoint shockwave" % path)
	for path in ["astra_j", "boros_j"]:
		var intent: CastIntent = prepare(path,"execute")
		target.health.current = 100
		combat.hit(source,target,intent.rank,intent.context)
		check(is_equal_approx(target.health.current,100 - intent.rank.damage * 1.1), "%s execute exact10percent" % path)
	var extra: Actor = make_actor(3,2)
	combat.actor_provider = func() -> Array[Actor]: return [source,target,extra]
	for actor: Actor in [target,extra]:
		actor.collision_layer = 2
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 12
		shape.shape = circle
		actor.add_child(shape)
	for path in ["astra_j", "vex_l"]:
		var intent: CastIntent = prepare(path,"pierce")
		extra.position = Vector2(100,0)
		extra.health = Health.new(10000)
		await frames(2)
		intent.runtime.definition.executor.execute_cast(intent,combat)
		await frames(50)
		check(target.health.current == 10000 - intent.rank.damage and extra.health.current == 10000 - intent.rank.damage, "%s augmented pierce hits both colliders once" % path)
	for path in ["astra_j", "vex_l"]:
		var intent: CastIntent = prepare(path,"on_kill_burst")
		extra.health = Health.new(10000)
		extra.position = Vector2(100,0)
		target.health.current = 1
		combat.hit(source,target,intent.rank,intent.context)
		combat.hit(source,target,intent.rank,intent.context)
		await frames(3)
		check(intent.context.budget.procs == 1 and intent.context.budget.seen.has("kill:2") and combat._queue.is_empty() and extra.health.current == 9980, "%s kill burst exact20damage once and settles" % path)
	# Basic projectile cores also use the exact shared pattern adapter.
	for path in ["astra_basic", "vex_basic"]:
		var intent: CastIntent = prepare(path,"multishot")
		check(intent.runtime.definition.executor.execute_cast(intent,combat) and intent.context.budget.projectiles == 2, "%s basic uses shared multishot adapter" % path)
		await frames(45)
	combat.queue_free()
	source.queue_free()
	target.queue_free()
	extra.queue_free()
	await process_frame
	print("RESULT shared effect matrix: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
