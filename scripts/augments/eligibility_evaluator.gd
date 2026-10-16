class_name EligibilityEvaluator
extends RefCounted

static func skill_eligible(definition: AugmentDefinition, runtime: SkillRuntime, manager: AugmentManager) -> bool:
	if definition == null or runtime == null or not runtime.valid() or not runtime.owner_alive() or runtime.rank == 0 or not definition.validate().is_empty() or definition.scope != "SKILL_TARGETED": return false
	if definition.requirements.required_character_id != &"" or manager.bound_rank(definition.id, runtime.definition.id) >= definition.max_rank: return false
	for capability in definition.requirements.required_capabilities:
		if not runtime.has_capability(capability): return false
	for prerequisite in definition.requirements.prerequisite_ids:
		if manager.bound_rank(prerequisite, runtime.definition.id) == 0 and manager.rank_for(prerequisite) == 0: return false
	for excluded in definition.requirements.excluded_ids:
		if manager.bound_rank(excluded, runtime.definition.id) > 0 or manager.rank_for(excluded) > 0: return false
	for effect in definition.effects:
		if not effect is MechanicEffectDefinition: return false
	return true
## M1 implements global stat cores only. Mechanic capabilities are enabled in M2.

static func global_stat_eligible(definition: AugmentDefinition, current_rank: int, owned: Dictionary[StringName, AugmentRuntime]) -> bool:
	if definition == null or not definition.validate().is_empty() or definition.scope != "GLOBAL" or not String(definition.id).begins_with("stat."):
		return false
	if definition.max_rank > 0 and current_rank >= definition.max_rank:
		return false
	if not definition.requirements.required_capabilities.is_empty() or definition.requirements.required_character_id != &"":
		return false
	for prerequisite in definition.requirements.prerequisite_ids:
		if not owned.has(prerequisite):
			return false
	for excluded in definition.requirements.excluded_ids:
		if owned.has(excluded):
			return false
	for effect in definition.effects:
		if not effect is StatModifierDefinition:
			return false
	return true
