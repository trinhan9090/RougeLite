class_name OfferGenerator
extends RefCounted

static func generate_bound(definitions: Array[AugmentDefinition], manager: AugmentManager, controller: SkillController, rng: RandomNumberGenerator, excluded_keys: Array[String] = []) -> Array[UpgradeOption]:
	if not controller.accepts_upgrades(): return []
	var pool: Array[UpgradeOption] = []
	var seen: Dictionary[String, bool] = {}
	for definition in definitions:
		if manager.can_apply(definition):
			var option := UpgradeOption.new()
			option.definition = definition
			option.current_rank = manager.rank_for(definition.id)
			if not seen.has(option.key()):
				pool.append(option)
				seen[option.key()] = true
		for slot in range(0, 5):
			var runtime: SkillRuntime = controller.runtime_for(slot)
			if not manager.can_bind(definition, runtime): continue
			var option := UpgradeOption.new()
			option.definition = definition
			option.target_skill_id = runtime.definition.id
			option.target_skill_name = runtime.definition.display_name
			option.slot = slot
			option.current_rank = manager.bound_rank(definition.id, runtime.definition.id)
			if not seen.has(option.key()):
				pool.append(option)
				seen[option.key()] = true
	for slot in range(1, 5):
		var runtime: SkillRuntime = controller.runtime_for(slot)
		if runtime == null or runtime.rank == 0 or runtime.rank >= runtime.definition.max_rank: continue
		var option := UpgradeOption.new()
		option.is_skill_rank = true
		option.slot = slot
		option.target_skill_id = runtime.definition.id
		option.target_skill_name = runtime.definition.display_name
		option.current_rank = runtime.rank
		pool.append(option)
	var result: Array[UpgradeOption] = []
	var fresh: Array[UpgradeOption] = pool.filter(func(option: UpgradeOption) -> bool: return not excluded_keys.has(option.key()))
	if fresh.size() >= 3: pool = fresh
	if pool.size() < 3: return result
	while result.size() < 3:
		var total: float = 0
		for option in pool: total += option.weight()
		var roll: float = rng.randf() * total
		var index: int = pool.size() - 1
		for candidate in range(pool.size()):
			roll -= pool[candidate].weight()
			if roll <= 0:
				index = candidate
				break
		result.append(pool[index])
		pool.remove_at(index)
	return result

static func generate(definitions: Array[AugmentDefinition], manager: AugmentManager, rng: RandomNumberGenerator) -> Array[AugmentDefinition]:
	var candidates: Array[AugmentDefinition] = []
	var seen: Dictionary[StringName, bool] = {}
	for definition in definitions:
		if manager.can_apply(definition) and not seen.has(definition.id):
			candidates.append(definition)
			seen[definition.id] = true
	var result: Array[AugmentDefinition] = []
	if candidates.size() < 3:
		return result
	while result.size() < 3:
		var total: float = 0.0
		for candidate in candidates:
			total += candidate.rarity_weight
		var roll: float = rng.randf() * total
		var selected: int = candidates.size() - 1
		for index in range(candidates.size()):
			roll -= candidates[index].rarity_weight
			if roll <= 0.0:
				selected = index
				break
		result.append(candidates[selected])
		candidates.remove_at(selected)
	return result
