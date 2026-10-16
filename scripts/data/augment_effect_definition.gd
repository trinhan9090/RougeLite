class_name AugmentEffectDefinition
extends Resource
## Numeric authoring contract only. M0 implements no gameplay effect executor.

@export var effect_id: StringName
@export_enum("PRIMARY_ONLY", "ONCE_PER_ROOT_CAST", "ALLOW_SECONDARY") var trigger_policy: String = "PRIMARY_ONLY"
@export var rank_values: Array[float] = []

func validate(expected_ranks: int) -> PackedStringArray:
	var errors := PackedStringArray()
	if effect_id == &"":
		errors.append("effect_id is required")
	if trigger_policy not in ["PRIMARY_ONLY", "ONCE_PER_ROOT_CAST", "ALLOW_SECONDARY"]:
		errors.append("invalid effect trigger policy")
	if rank_values.size() != expected_ranks:
		errors.append("effect rank values must match augment ranks")
	for value in rank_values:
		if not is_finite(value) or value < 0.0:
			errors.append("effect values must be finite and nonnegative")
	return errors
