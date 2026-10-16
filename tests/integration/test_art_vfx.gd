extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL ",label)
func run_tests() -> void:
	var source := Actor.new()
	source.actor_id = 1
	source.stats_definition = ActorStatDefinition.new()
	root.add_child(source)
	var target := Actor.new()
	target.actor_id = 2
	target.team = 2
	target.position = Vector2(60,0)
	target.stats_definition = ActorStatDefinition.new()
	root.add_child(target)
	target.health = Health.new(100000)
	var combat := CombatService.new()
	combat.rng = RunRng.new(42).stream(&"combat")
	combat.actor_provider = func() -> Array[Actor]: return [source,target]
	root.add_child(combat)
	var factory := CombatVisualFactory.new()
	factory.combat = combat
	root.add_child(factory)
	for hero: String in ["astra","vex","boros"]:
		for action: String in ["basic","j","k","l","i"]:
			source.position = Vector2.ZERO
			source.motion_active = false
			var definition := load("res://content/skills/%s_%s.tres" % [hero,action]) as SkillDefinition
			var runtime := SkillRuntime.new(definition,1)
			runtime.unlock_for_level(11)
			var intent := CastIntent.new()
			intent.source_ref = weakref(source)
			intent.target_ref = weakref(target)
			intent.runtime = runtime
			intent.rank = runtime.effective_rank()
			intent.context = combat.next_context(source,definition.id)
			intent.context.runtime = runtime
			intent.direction = Vector2.RIGHT
			intent.aim_point = target.position
			factory.accepted_events.clear()
			check(definition.executor.execute_cast(intent,combat),hero+" "+action+" real executor accepted")
			await physics_frame
			await process_frame
			if intent.rank.projectile_speed > 0:
				var bound: bool = false
				for child in combat.get_children():
					if child is CombatProjectile: bound = bound or child.get_meta("art_bound",false)
				check(bound,hero+" "+action+" visual bound to actual projectile")
			else:
				check(not factory.accepted_events.is_empty(),hero+" "+action+" confirmed visual event")
			combat.clear_transients()
			factory.clear()
			await process_frame
	# Actual universal split: two supported executors share the same visual binding.
	for path: String in ["astra_j","vex_l"]:
		var runtime := SkillRuntime.new(load("res://content/skills/"+path+".tres") as SkillDefinition,1)
		runtime.unlock_for_level(11)
		var manager := AugmentManager.new()
		check(manager.apply_bound(load("res://content/augments/mechanics/projectile_split.tres") as AugmentDefinition,runtime),path+" split eligible")
		var intent := CastIntent.new()
		intent.source_ref = weakref(source)
		intent.runtime = runtime
		intent.rank = runtime.effective_rank()
		intent.rank.behavior = null
		intent.context = combat.next_context(source,runtime.definition.id)
		intent.context.runtime = runtime
		intent.context.manager = manager
		intent.direction = Vector2.RIGHT
		check(runtime.definition.executor.execute_cast(intent,combat),path+" split actual cast")
		await process_frame
		var bound: int = 0
		for child in combat.get_children():
			if child is CombatProjectile and child.get_meta("art_bound",false): bound += 1
		check(bound==intent.context.budget.projectiles and bound>=2,path+" every real split projectile has VFX")
		combat.clear_transients()
		factory.clear()
		await process_frame
	var incompatible := SkillRuntime.new(load("res://content/skills/boros_j.tres") as SkillDefinition,1)
	incompatible.unlock_for_level(11)
	var manager := AugmentManager.new()
	check(not manager.apply_bound(load("res://content/augments/mechanics/projectile_split.tres") as AugmentDefinition,incompatible),"Boros slam split rejected; no projectile VFX")
	# Bounds and geometry are cosmetic: no combat children are allocated by impacts.
	for index in range(100):
		combat.visual_event.emit({"kind":"area","position":Vector2.ZERO,"radius":123.0})
	check(factory.get_child_count() == factory.LIMIT and factory.dropped>=20,"cosmetic impact cap80")
	check(combat.get_child_count()==0,"cosmetics do not consume projectile budget")
	var effect := factory.get_child(0) as CombatVisualEffect
	check(effect.radius==123,"visual radius copies actual geometry")
	var before: float = effect.remaining
	paused = true
	for index in range(3): await process_frame
	check(effect.remaining==before,"VFX pauses with simulation")
	paused = false
	factory.free()
	combat.free()
	source.free()
	target.free()
	print("RESULT art VFX checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
