class_name StatModifierDefinition
extends AugmentEffectDefinition

@export var stat_key: StringName
@export_enum("MULTIPLY_BASE", "ADD_BASE") var operation: String = "MULTIPLY_BASE"
@export var cap: float = -1.0

func validate(expected_ranks: int) -> PackedStringArray:
	var errors := super.validate(expected_ranks)
	if stat_key not in [&"max_hp", &"damage_multiplier", &"attack_speed_multiplier", &"move_speed", &"crit_chance", &"crit_multiplier", &"cooldown_reduction", &"pickup_radius"] or operation not in ["MULTIPLY_BASE", "ADD_BASE"]:
		errors.append("invalid stat modifier key/operation")
	if not is_finite(cap):
		errors.append("stat cap must be finite (-1 means uncapped)")
	return errors
