class_name SkillDefinition
extends ContentDefinition

@export_range(0, 4) var slot: int = 0
@export var unlock_level: int = 1
@export var max_rank: int = 1
@export var tags: Array[StringName] = []
@export var declared_capabilities: Array[StringName] = []
@export var executor: SkillExecutorDefinition
@export var targeting: TargetingDefinition
@export var rank_scaling: Array[SkillRankDefinition] = []

func validate() -> PackedStringArray:
	var errors := super.validate()
	var unlocks: Array[int] = [1, 3, 6, 9, 11]
	var caps: Array[int] = [1, 4, 4, 4, 3]
	if slot < 0 or slot > 4:
		errors.append("%s: slot must be 0..4" % id)
	elif unlock_level != unlocks[slot] or max_rank != caps[slot]:
		errors.append("%s: slot %d requires unlock %d / max_rank %d" % [id, slot, unlocks[slot], caps[slot]])
	if rank_scaling.size() != max_rank or max_rank < 1:
		errors.append("%s: missing ranks; expected %d, got %d" % [id, max_rank, rank_scaling.size()])
	for index in range(rank_scaling.size()):
		var entry: SkillRankDefinition = rank_scaling[index]
		if entry == null:
			errors.append("%s: empty rank reference at %d" % [id, index])
		else:
			if entry.rank != index + 1:
				errors.append("%s: ranks must be contiguous and ordered" % id)
			for message in entry.validate():
				errors.append("%s: %s" % [id, message])
	if executor == null or executor.executor_id == &"":
		errors.append("%s: executor reference/ID is required" % id)
	else:
		errors.append_array(executor.validate())
		for capability in declared_capabilities:
			if not executor.supported_capabilities().has(capability):
				errors.append("%s: executor %s does not implement capability %s" % [id, executor.executor_id, capability])
		if executor is BasicAttackExecutorDefinition and (executor as BasicAttackExecutorDefinition).strategy == "projectile":
			for entry in rank_scaling:
				if entry != null and entry.projectile_speed <= 0.0:
					errors.append("%s: basic projectile speed must be positive" % id)
		if executor is EffectExecutorDefinition:
			var adapter := executor as EffectExecutorDefinition
			for entry in rank_scaling:
				if entry == null: continue
				if adapter.kind == "projectile" and entry.projectile_speed <= 0: errors.append("%s: projectile adapter requires speed" % id)
				if adapter.kind == "shield" and (entry.shield <= 0 or entry.duration <= 0): errors.append("%s: shield adapter requires amount/duration" % id)
				if adapter.kind == "dash" and entry.range_px <= 0: errors.append("%s: dash adapter requires distance" % id)
				if adapter.kind in ["area", "beam"] and entry.radius_px <= 0: errors.append("%s: area/beam adapter requires radius" % id)
	if targeting == null:
		errors.append("%s: targeting reference is required" % id)
	else:
		errors.append_array(targeting.validate())
	return errors
