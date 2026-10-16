class_name AugmentManager
extends RefCounted
## No character identities enter modifier logic. Definitions remain unchanged.

var instances: Dictionary[StringName, AugmentRuntime] = {}
var _bonuses: Dictionary[StringName, float] = {}
var _baselines: Dictionary[StringName, float] = {}
var _bound: Dictionary[String, Dictionary] = {}

func policy(skill_id: StringName, operation: StringName) -> StringName:
	var keys: Array = _bound.keys()
	keys.sort()
	for key: String in keys:
		var entry: Dictionary = _bound[key]
		if entry.skill != skill_id: continue
		for effect: AugmentEffectDefinition in entry.definition.effects:
			if effect.effect_id == operation: return StringName(effect.trigger_policy)
	return &"PRIMARY_ONLY"

func bound_rank(id: StringName, skill_id: StringName) -> int:
	return int(_bound.get("%s:%s" % [id, skill_id], {}).get("rank", 0))

func can_bind(definition: AugmentDefinition, runtime: SkillRuntime) -> bool:
	return EligibilityEvaluator.skill_eligible(definition, runtime, self)

func apply_bound(definition: AugmentDefinition, runtime: SkillRuntime) -> bool:
	if not can_bind(definition, runtime): return false
	var key: String = "%s:%s" % [definition.id, runtime.definition.id]
	_bound[key] = {"rank": bound_rank(definition.id, runtime.definition.id) + 1, "definition": definition.duplicate(true), "skill": runtime.definition.id}
	return true

func value(skill_id: StringName, operation: StringName, auxiliary: bool = false) -> float:
	# Stable IDs make accumulation independent of acquisition order.
	var keys: Array = _bound.keys()
	keys.sort()
	var result: float = 0.0
	for key: String in keys:
		var entry: Dictionary = _bound[key]
		if entry.skill != skill_id: continue
		for raw: AugmentEffectDefinition in entry.definition.effects:
			var effect := raw as MechanicEffectDefinition
			if effect != null and effect.effect_id == operation:
				result += effect.auxiliary_values[entry.rank - 1] if auxiliary else effect.rank_values[entry.rank - 1]
	return result

func rank_for(id: StringName) -> int:
	return instances[id].rank if instances.has(id) else 0

func can_apply(definition: AugmentDefinition) -> bool:
	return EligibilityEvaluator.global_stat_eligible(definition, rank_for(definition.id) if definition != null else 0, instances)

func apply(definition: AugmentDefinition, actor: Actor) -> bool:
	if not is_instance_valid(actor) or not actor.health.is_alive() or not can_apply(definition):
		return false
	if not instances.has(definition.id):
		var instance := AugmentRuntime.new()
		instance.augment_id = definition.id
		instances[definition.id] = instance
	instances[definition.id].rank += 1
	for raw_effect in definition.effects:
		var effect := raw_effect as StatModifierDefinition
		var key: StringName = effect.stat_key
		if not _baselines.has(key):
			_baselines[key] = actor.stats.get(key)
		_bonuses[key] = _bonuses.get(key, 0.0) + effect.rank_values[0]
		var base: float = _baselines[key]
		var value: float = base * (1.0 + _bonuses[key]) if effect.operation == "MULTIPLY_BASE" else base + _bonuses[key]
		if effect.cap >= 0.0:
			value = minf(value, effect.cap)
		actor.stats.set(key, value)
		if key == &"max_hp":
			var ratio: float = actor.health.current / actor.health.maximum
			actor.health.maximum = value * actor.factor(&"max_hp")
			actor.health.commit_resolved_hp(actor.health.maximum * ratio)
	return true
