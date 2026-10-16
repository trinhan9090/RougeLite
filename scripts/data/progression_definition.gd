class_name ProgressionDefinition
extends ContentDefinition

@export var base_xp: float = 25.0
@export var linear_xp: float = 12.0
@export var power_xp: float = 1.8
@export var exponent: float = 1.45
@export var orb_lifetime: float = 45.0
@export var collect_radius: float = 20.0

func validate() -> PackedStringArray:
	var errors := super.validate()
	for field: StringName in [&"base_xp", &"linear_xp", &"power_xp", &"exponent", &"orb_lifetime", &"collect_radius"]:
		var value: float = get(field)
		if not is_finite(value) or value < 0.0:
			errors.append("%s: invalid %s" % [id, field])
	if base_xp <= 0.0 or exponent <= 0.0 or collect_radius <= 0.0 or orb_lifetime < 45.0:
		errors.append("%s: XP curve/orb bounds invalid" % id)
	return errors

func threshold(level: int) -> int:
	var offset: float = maxf(0.0, level - 1)
	return maxi(1, roundi(base_xp + linear_xp * offset + power_xp * pow(offset, exponent)))
