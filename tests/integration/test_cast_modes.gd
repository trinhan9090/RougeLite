extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS ", label)
	else:
		failures += 1
		printerr("FAIL ", label)

func run_tests() -> void:
	var owner := Actor.new()
	owner.actor_id = 1
	owner.stats_definition = ActorStatDefinition.new()
	root.add_child(owner)
	owner.stats.crit_chance = 0
	var target := Actor.new()
	target.team = 2
	target.position = Vector2(30, 0)
	target.stats_definition = ActorStatDefinition.new()
	root.add_child(target)
	target.stats.armor = 0
	var combat := CombatService.new()
	combat.rng = RunRng.new(7).stream(&"combat")
	root.add_child(combat)
	var definitions := FoundationFactory.character().active_skills
	for definition in definitions:
		var executor := BasicAttackExecutorDefinition.new()
		executor.executor_id = &"executor.fixture_melee"
		executor.strategy = "melee"
		definition.executor = executor
		definition.declared_capabilities = executor.supported_capabilities()
		definition.targeting.acquisition_radius = 100
		for rank in definition.rank_scaling:
			rank.range_px = 100
			rank.damage = 5
	var controller := SkillController.new(1, definitions)
	controller.bind(owner, combat)
	controller.candidates = [target]
	check(not controller.request_cast(1), "locked slot cannot cast")
	controller.sync_level(3)
	controller.set_mode(&"MANUAL")
	check(controller.auto_step() == 0 and target.health.current == 130, "manual mode never auto casts")
	var event := InputEventAction.new()
	event.action = &"active_1"
	event.pressed = true
	check(SkillInputRouter.handle(event, controller, Vector2(30, 0)), "manual slot input reaches common cast pipeline")
	check(target.health.current == 125 and controller.runtime_for(1).cooldown_remaining == 7, "manual exact damage and cooldown")
	check(not controller.request_cast(1), "cooldown rejects repeated request")
	controller.advance_cooldowns(7)
	controller.set_mode(&"AUTO")
	check(controller.auto_step() == 1 and target.health.current == 120, "auto uses identical damage/cooldown pipeline")
	controller.advance_cooldowns(7)
	controller.candidates.clear()
	check(controller.auto_step() == 0 and controller.runtime_for(1).cooldown_ready(), "no target spends no cooldown")
	controller.candidates = [target]
	paused = true
	check(not controller.request_cast(1), "paused simulation rejects cast")
	paused = false
	var stun := StatusEffectDefinition.new()
	stun.kind = "stun"
	owner.statuses.apply(stun)
	check(not controller.request_cast(1), "stun rejects cast")
	owner.statuses.advance(10)
	var mechanic := load("res://content/augments/mechanics/execute.tres") as AugmentDefinition
	check(AugmentManager.new().can_bind(mechanic, controller.runtime_for(1)), "live bound owner accepts compatible upgrade")
	var stats: Array[AugmentDefinition] = []
	for name in ["damage", "max_hp", "attack_speed"]: stats.append(load("res://content/augments/stats/%s.tres" % name) as AugmentDefinition)
	check(OfferGenerator.generate_bound(stats, AugmentManager.new(), controller, RunRng.new(1).stream(&"offers")).size() == 3, "live owner receives three offers")
	owner.health.commit_resolved_hp(0)
	check(not controller.request_cast(1), "dead owner rejects cast")
	check(not AugmentManager.new().can_bind(mechanic, controller.runtime_for(1)), "dead bound owner rejects mechanic upgrade")
	check(OfferGenerator.generate_bound(stats, AugmentManager.new(), controller, RunRng.new(1).stream(&"offers")).is_empty() and not controller.upgrade_rank(1), "dead owner rejects offers and skill rank")
	owner.queue_free()
	target.queue_free()
	combat.queue_free()
	await process_frame
	print("RESULT cast modes: checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
