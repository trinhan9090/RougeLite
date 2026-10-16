class_name BossDefinition
extends ContentDefinition

@export var actor: EnemyDefinition
@export var phase_thresholds: Array[float] = [0.4]
@export var telegraph_seconds: float = 1.0
@export_enum("stone","ember") var archetype: String = "stone"

func validate() -> PackedStringArray:
	var errors := super.validate()
	if actor == null:
		errors.append("%s: boss actor reference required" % id)
	if not is_finite(telegraph_seconds) or telegraph_seconds <= 0.0:
		errors.append("%s: positive telegraph required" % id)
	var previous: float = 1.0
	for threshold in phase_thresholds:
		if not is_finite(threshold) or threshold <= 0.0 or threshold >= previous:
			errors.append("%s: phase thresholds must descend within (0,1)" % id)
		previous = threshold
	return errors

func references() -> Array[Resource]:
	var result := super.references()
	result.append(actor)
	return result
