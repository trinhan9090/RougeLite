class_name CombatContext
extends RefCounted

var root_cast_id: int = 0
var event_id: int = 0
var owner_actor_id: int = 0
var source_skill_id: StringName
var source_augment_id: StringName
var parent_event_id: int = 0
var generation_depth: int = 0
var proc_budget_remaining: int:
	get: return budget.proc_limit - budget.procs
var rng_stream_id: StringName = &"combat"
var is_secondary: bool = false
var is_echo: bool = false
var can_trigger_on_hit: bool = true
var can_trigger_on_kill: bool = true
var budget: CastBudget = CastBudget.new()
var manager: AugmentManager
var runtime: SkillRuntime
var projectile_id: int = 0
var _snapshot_ready: bool = false
var _modifiers: Dictionary[StringName, Array] = {}

func freeze_modifiers() -> void:
	if _snapshot_ready: return
	_snapshot_ready = true
	if manager == null: return
	for operation in MechanicEffectDefinition.OPERATIONS:
		_modifiers[operation] = [manager.value(source_skill_id, operation), manager.value(source_skill_id, operation, true), manager.policy(source_skill_id, operation)]

func value(operation: StringName, auxiliary: bool = false) -> float:
	freeze_modifiers()
	var values: Array = _modifiers.get(operation, [0.0, 0.0])
	return values[1] if auxiliary else values[0]

func allows(operation: StringName) -> bool:
	freeze_modifiers()
	var values: Array = _modifiers.get(operation, [0.0, 0.0, &"PRIMARY_ONLY"])
	var policy: StringName = values[2]
	if policy == &"PRIMARY_ONLY": return not is_secondary
	if policy == &"ONCE_PER_ROOT_CAST": return budget.claim("policy:%s" % operation)
	return policy == &"ALLOW_SECONDARY"

func event_copy(collision_projectile_id: int = 0) -> CombatContext:
	freeze_modifiers()
	var result := CombatContext.new()
	result.root_cast_id = root_cast_id
	budget.events += 1
	result.event_id = root_cast_id * 1000000 + budget.events
	result.parent_event_id = event_id
	result.owner_actor_id = owner_actor_id
	result.source_skill_id = source_skill_id
	result.source_augment_id = source_augment_id
	result.generation_depth = generation_depth
	result.budget = budget
	result.manager = manager
	result.runtime = runtime
	result.is_secondary = is_secondary
	result.is_echo = is_echo
	result.can_trigger_on_hit = can_trigger_on_hit
	result.can_trigger_on_kill = can_trigger_on_kill
	result.projectile_id = collision_projectile_id
	result._snapshot_ready = true
	result._modifiers = _modifiers.duplicate()
	return result

func child(augment_id: StringName, echo: bool = false) -> CombatContext:
	if not budget.spend_proc(generation_depth + 1): return null
	var result: CombatContext = event_copy()
	result.owner_actor_id = owner_actor_id
	result.source_skill_id = source_skill_id
	result.source_augment_id = augment_id
	result.generation_depth = generation_depth + 1
	result.budget = budget
	result.manager = manager
	result.runtime = runtime
	result.is_secondary = true
	result.is_echo = echo or is_echo
	result.can_trigger_on_hit = true
	result.can_trigger_on_kill = true
	return result
