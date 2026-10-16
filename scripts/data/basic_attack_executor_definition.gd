class_name BasicAttackExecutorDefinition
extends SkillExecutorDefinition

@export_enum("projectile", "melee") var strategy: String = "projectile"

func validate() -> PackedStringArray:
	var errors := super.validate()
	if strategy not in ["projectile", "melee"]:
		errors.append("unknown basic attack strategy")
	return errors

func supported_capabilities() -> Array[StringName]:
	var caps: Array[StringName] = [&"damage", &"on_hit_hook", &"on_kill_hook"]
	if strategy == "projectile": caps.append_array([&"modify_projectile_angle", &"spawn_projectile_pattern", &"modify_projectile_count", &"pierce_hit", &"projectile_steering", &"repeat_cast"])
	return caps

func execute(combat: CombatService, source: Actor, target: Actor, rank: SkillRankDefinition, context: CombatContext) -> bool:
	if strategy == "projectile":
		if context.runtime != null:
			var intent := CastIntent.new()
			intent.source_ref = weakref(source)
			intent.target_ref = weakref(target)
			intent.runtime = context.runtime
			intent.rank = rank
			intent.context = context
			intent.aim_point = TargetingService.intercept_point(source.global_position, target, rank.projectile_speed)
			intent.direction = source.global_position.direction_to(intent.aim_point)
			var executor := EffectExecutorDefinition.new()
			executor.executor_id = &"executor.projectile"
			return combat.execute_effect(executor, intent)
		return combat.spawn_projectile(source, target, rank, context)
	if strategy == "melee":
		combat.hit(source, target, rank, context)
		return true
	return false

func execute_cast(intent: CastIntent, combat: CombatService) -> bool:
	if not is_instance_valid(intent.target()):
		return false
	return execute(combat, intent.source(), intent.target(), intent.rank, intent.context)
