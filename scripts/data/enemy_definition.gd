class_name EnemyDefinition
extends ContentDefinition

@export var stats: ActorStatDefinition
@export var damage: float = 8.0
@export var xp_reward: int = 6
@export var attack_interval: float = 1.0

func validate() -> PackedStringArray:
	var errors := super.validate()
	if stats == null:
		errors.append("%s: stats reference required" % id)
	else:
		errors.append_array(stats.validate())
	if not is_finite(damage) or damage < 0.0 or xp_reward < 0 or not is_finite(attack_interval) or attack_interval <= 0.0:
		errors.append("%s: invalid enemy damage/reward/interval" % id)
	return errors
