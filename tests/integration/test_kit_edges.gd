extends "res://tests/integration/test_full_kits.gd"
func reset_target() -> void:
	target.health = Health.new(10000)
	target.health.depleted.connect(target._on_depleted)
	target.mark_left = 0
	target.statuses = StatusController.new()
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
	reset_target()
	var other := Actor.new()
	other.actor_id = 3
	other.team = 2
	other.position = Vector2(100,0)
	other.stats_definition = ActorStatDefinition.new()
	root.add_child(other)
	other.stats.armor = 0
	other.health = Health.new(10000)
	combat = CombatService.new()
	combat.rng = RunRng.new(61).stream(&"combat")
	combat.actor_provider = func() -> Array[Actor]: return [source,target,other]
	root.add_child(combat)
	var trap: CastIntent = prepare("astra_j",4)
	combat.hit(source,target,trap.rank,trap.context)
	target.health.current = 1
	var lethal := SkillRankDefinition.new()
	lethal.damage = 2
	lethal.damage_type = "TRUE"
	combat.hit(source,target,lethal,combat.next_context(source,&"test.kill"))
	await frames(4)
	check(other.health.current == 9970,"Astra rooted death fires30damage pulse")
	reset_target()
	var slam: CastIntent = prepare("boros_j",4)
	slam.aim_point = source.position
	slam.runtime.definition.executor.execute_cast(slam,combat)
	await frames(35)
	check(is_equal_approx(10000-target.health.current,(55+source.health.maximum*.03)*1.45),"Boros second ring repeats45percent including HP scaling")
	reset_target()
	var roll: CastIntent = prepare("vex_k",4)
	roll.runtime.definition.executor.execute_cast(roll,combat)
	roll.runtime.commit_cast()
	target.health.current = 1
	combat.hit(source,target,lethal,combat.next_context(source,&"test.kill"))
	check(is_equal_approx(roll.runtime.cooldown_remaining,10.5),"Vex roll kill refunds1.5s once")
	reset_target()
	target.health.current = 1
	combat.hit(source,target,lethal,combat.next_context(source,&"test.kill"))
	check(is_equal_approx(roll.runtime.cooldown_remaining,10.5),"Vex roll cannot refund on second kill")
	await frames(25)
	source.position = Vector2.ZERO
	source.clear_temporary()
	reset_target()
	var charge: CastIntent = prepare("boros_l",4)
	target.position = Vector2(100,0)
	charge.runtime.definition.executor.execute_cast(charge,combat)
	await frames(150)
	check(is_equal_approx(10000-target.health.current,100),"Boros charge60 plus four10damage path-trail ticks")
	source.position = Vector2.ZERO
	reset_target()
	other.health.current = 10000
	var bounce_count: int = 0
	for attempt in range(80):
		var storm: CastIntent = prepare("vex_i",3)
		combat.hit(source,target,storm.rank,storm.context)
		bounce_count += storm.context.budget.procs
		await frames(2)
	check(bounce_count > 0 and bounce_count < 80 and is_equal_approx(10000-other.health.current,bounce_count*5),"Vex storm budgeted15percent bounce hits distinct target at50percent damage")
	combat.queue_free()
	source.queue_free()
	target.queue_free()
	other.queue_free()
	await process_frame
	print("RESULT kit edges: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
