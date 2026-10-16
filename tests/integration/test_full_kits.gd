extends SceneTree
var checks: int = 0
var failures: int = 0
var source: Actor
var target: Actor
var combat: CombatService
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks += 1
	if value: print("PASS ",label)
	else:
		failures += 1
		printerr("FAIL ",label)
func frames(count: int) -> void:
	for index in range(count): await physics_frame
func prepare(path: String, rank: int) -> CastIntent:
	var skill := SkillRuntime.new(load("res://content/skills/%s.tres" % path) as SkillDefinition,1)
	skill.unlock_for_level(11)
	for index in range(rank-1): skill.upgrade_rank()
	var result := CastIntent.new()
	result.source_ref = weakref(source)
	result.target_ref = weakref(target)
	result.runtime = skill
	result.rank = skill.effective_rank()
	result.context = combat.next_context(source,skill.definition.id)
	result.context.runtime = skill
	result.direction = Vector2.RIGHT
	result.aim_point = target.position
	return result
func run_tests() -> void:
	source = Actor.new()
	source.actor_id = 1
	source.stats_definition = ActorStatDefinition.new()
	root.add_child(source)
	source.stats.crit_chance = 0
	target = Actor.new()
	target.actor_id = 2
	target.team = 2
	target.position = Vector2(60,0)
	target.stats_definition = ActorStatDefinition.new()
	root.add_child(target)
	target.stats.armor = 0
	target.health = Health.new(10000)
	combat = CombatService.new()
	combat.rng = RunRng.new(19).stream(&"combat")
	combat.actor_provider = func() -> Array[Actor]: return [source,target]
	root.add_child(combat)
	for identity in ["astra","vex","boros"]:
		for key in ["j","k","l","i"]:
			var definition := load("res://content/skills/%s_%s.tres" % [identity,key]) as SkillDefinition
			check(definition.validate().is_empty() and definition.rank_scaling.all(func(rank: SkillRankDefinition) -> bool: return rank.behavior != null), "%s %s complete rank graph" % [identity,key])
	var j: CastIntent = prepare("astra_j",3)
	var before: float = target.health.current
	combat.hit(source,target,j.rank,j.context)
	check(target.health.current == before - 54 and target.statuses.movement_factor() == 0,"Astra J rank3 exact magic54/root")
	target.statuses.advance(1.66)
	check(target.statuses.movement_factor() == 1,"Astra root rank3 expires1.65s")
	var guard: CastIntent = prepare("astra_k",4)
	guard.runtime.definition.executor.execute_cast(guard,combat)
	check(source.health.shield_total() == 95 and is_equal_approx(source.factor(&"move_speed"),1.15),"Astra K rank4 shield95/move buff")
	source.advance_effects(3.1)
	check(source.factor(&"move_speed") == 1,"Astra move buff expires independently")
	var incoming := SkillRankDefinition.new()
	incoming.damage = 20
	incoming.damage_type = "TRUE"
	before = target.health.current
	combat.hit(target,source,incoming,combat.next_context(target,&"enemy.test"))
	await frames(3)
	check(target.health.current == before - 15,"Astra blocked pulse exact15")
	combat.rank_effects.advance(4.1)
	await frames(15)
	check(target.health.current == before - 60,"Astra expiry blast exact45")
	var beam: CastIntent = prepare("astra_i",3)
	before = target.health.current
	beam.runtime.definition.executor.execute_cast(beam,combat)
	await frames(190)
	check(target.health.current == before - 120 - 72,"Astra beam120 plus six12 burn ticks")
	var barrage: CastIntent = prepare("vex_j",1)
	barrage.runtime.definition.executor.execute_cast(barrage,combat)
	check(barrage.context.budget.projectiles == 1,"Vex barrage first shot immediate")
	await frames(25)
	check(barrage.context.budget.projectiles == 4,"Vex four spaced shots by0.4s")
	await frames(60)
	var roll: CastIntent = prepare("vex_k",4)
	roll.runtime.definition.executor.execute_cast(roll,combat)
	check(is_equal_approx(source.factor(&"attack_speed"),1.3) and source.extra_basic == 1,"Vex roll buff and next-basic double shot")
	await frames(22)
	check(is_equal_approx(source.position.x,190),"Vex roll travels190px")
	source.position = Vector2.ZERO
	var round_cast: CastIntent = prepare("vex_l",4)
	target.is_boss = true
	before = target.health.current
	combat.hit(source,target,round_cast.rank,round_cast.context)
	check(is_equal_approx(before-target.health.current,65*1.35) and target.mark_left == 3,"Vex round boss bonus35percent and mark")
	target.is_boss = false
	target.mark_left = 0
	var slam: CastIntent = prepare("boros_j",3)
	before = target.health.current
	combat.hit(source,target,slam.rank,slam.context)
	check(is_equal_approx(before-target.health.current,55 + source.health.maximum*.03),"Boros slam maxHP scaling")
	var iron: CastIntent = prepare("boros_k",4)
	source.clear_temporary()
	source.health.current = 50
	iron.runtime.definition.executor.execute_cast(iron,combat)
	check(source.factor(&"damage_taken") == .75 and source.health.shield_total() == 95,"Boros shield/reduction exact")
	before = target.health.current
	combat.hit(target,source,incoming,combat.next_context(target,&"enemy.test"))
	await frames(4)
	check(is_equal_approx(before-target.health.current,20*.75*.15),"Boros native reflection postmitigation15percent")
	combat.rank_effects.advance(4)
	check(is_equal_approx(source.health.current,53),"Boros shield expiry heals20percent absorbed")
	source.clear_temporary()
	source.health.current = source.health.maximum*.5
	var transform: CastIntent = prepare("boros_i",3)
	var original: float = source.health.maximum
	transform.runtime.definition.executor.execute_cast(transform,combat)
	check(is_equal_approx(source.health.maximum,original*1.4) and is_equal_approx(source.health.current/source.health.maximum,.5),"transform adds40percent maxHP preserving ratio")
	transform.runtime.definition.executor.execute_cast(transform,combat)
	check(is_equal_approx(source.health.maximum,original*1.4) and is_equal_approx(source.health.current/source.health.maximum,.5),"transform refresh cannot stack/free-heal")
	check(source.factor(&"range") == 1.45 and source.native_pulse_scale == .35,"transform melee range/pulse")
	source.advance_effects(9.1)
	check(is_equal_approx(source.health.maximum,original) and source.native_pulse_scale == 0,"transform restores stats at expiry")
	var echo_cast: CastIntent = prepare("boros_j",3)
	var manager := AugmentManager.new()
	manager.apply_bound(load("res://content/augments/mechanics/echo_cast.tres") as AugmentDefinition,echo_cast.runtime)
	echo_cast.context.manager = manager
	var echo_before: float = target.health.current
	echo_cast.runtime.definition.executor.execute_cast(echo_cast,combat)
	await frames(50)
	check(is_equal_approx(echo_before-target.health.current,(55+source.health.maximum*.03)*1.35),"Echo scales HP-based skill damage as well as flat damage")
	source.clear_temporary()
	var profile := load("res://content/characters/boros_loadout.tres") as CombatLoadoutDefinition
	var controller := SkillController.new(1,profile.active_skills)
	controller.bind(source,combat)
	controller.sync_level(11)
	controller.upgrade_rank(1)
	controller.upgrade_rank(3)
	controller.candidates = [target]
	source.health.shields.append(ShieldInstance.new(50,4))
	target.position = Vector2(150,0)
	check(controller.request_cast(1),"Auto self-area uses rank2 radius170 despite active shield")
	check(controller.request_cast(4),"Auto self-buff is not suppressed by an unrelated shield")
	target.position = Vector2(280,0)
	check(controller.request_cast(3),"Auto dash uses rank2 range300")
	await frames(25)
	controller.advance_cooldowns(100)
	var root_status := StatusEffectDefinition.new()
	source.statuses.apply(root_status)
	check(not controller.request_cast(3),"root prevents dash movement without consuming cooldown")
	combat.queue_free()
	source.queue_free()
	target.queue_free()
	await process_frame
	print("RESULT full kits: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
