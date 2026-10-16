class_name StatusEffectDefinition
extends Resource

@export_enum("root", "slow", "stun") var kind: String = "root"
@export var duration: float = 1.25
@export var strength: float = 0.25

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if kind not in ["root", "slow", "stun"] or not is_finite(duration) or duration <= 0 or not is_finite(strength) or strength < 0 or strength > 1: errors.append("invalid status")
	return errors
