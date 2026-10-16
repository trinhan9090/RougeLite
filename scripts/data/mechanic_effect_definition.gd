class_name MechanicEffectDefinition
extends AugmentEffectDefinition
const OPERATIONS: Array[StringName] = [&"split", &"multishot", &"pierce", &"echo", &"area", &"explosion", &"kill_burst", &"refund", &"reflect", &"dash_wave", &"execute", &"homing"]
@export var auxiliary_values: Array[float] = []

func describe_rank(rank: int) -> String:
	if rank <= 0: return "None"
	var value: float = rank_values[rank - 1]
	var auxiliary: float = auxiliary_values[rank - 1]
	match effect_id:
		&"split": return "%d extra shots, %d%% damage" % [int(value), roundi(auxiliary * 100)]
		&"multishot": return "+%d primary shots" % int(value)
		&"pierce": return "+%d targets pierced" % int(value)
		&"homing": return "+%d%% turning strength" % roundi(value * 100)
		&"echo": return "%d%% damage echo after 0.6s" % roundi(value * 100)
		&"area": return "+%d%% radius" % roundi(value * 100)
		&"explosion": return "%.0f magic damage, %.0fpx radius" % [value, auxiliary]
		&"kill_burst": return "%.0f damage, 65px radius" % value
		&"refund": return "%d%% chance; refund 10%% CD" % roundi(value * 100)
		&"reflect": return "%d%% of absorbed damage" % roundi(value * 100)
		&"dash_wave": return "%.0f physical damage, 90px" % value
		&"execute": return "+%d%% damage below 25%% HP" % roundi(value * 100)
	return ""

func required_capabilities() -> Array[StringName]:
	var mapping: Dictionary = {
		&"split": [&"modify_projectile_angle", &"spawn_projectile_pattern"], &"multishot": [&"modify_projectile_count"],
		&"pierce": [&"pierce_hit"], &"echo": [&"repeat_cast"], &"area": [&"resize_area"],
		&"explosion": [&"on_hit_hook", &"damage"], &"kill_burst": [&"on_kill_hook"], &"refund": [&"cooldown_manage"],
		&"reflect": [&"modify_shield", &"damage_taken_hook"], &"dash_wave": [&"dash_completed_hook"], &"execute": [&"damage"], &"homing": [&"projectile_steering"]}
	var result: Array[StringName] = []
	result.assign(mapping.get(effect_id, []))
	return result

func validate(expected_ranks: int) -> PackedStringArray:
	var errors := super.validate(expected_ranks)
	if effect_id not in OPERATIONS: errors.append("unknown mechanic operation")
	if auxiliary_values.size() != expected_ranks: errors.append("mechanic auxiliary values must match ranks")
	for value in auxiliary_values:
		if not is_finite(value) or value < 0: errors.append("invalid auxiliary value")
	return errors
