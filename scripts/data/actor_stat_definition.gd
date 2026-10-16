class_name ActorStatDefinition
extends Resource

@export var max_hp: float = 130.0
@export var move_speed: float = 240.0
@export var armor: float = 5.0
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 1.5

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if not is_finite(max_hp) or max_hp <= 0.0:
		errors.append("max_hp must be finite and positive")
	if not is_finite(move_speed) or move_speed <= 0.0:
		errors.append("move_speed must be finite and positive")
	if not is_finite(armor):
		errors.append("armor must be finite")
	if not is_finite(crit_chance) or crit_chance < 0.0 or crit_chance > 1.0:
		errors.append("crit_chance must be in [0,1]")
	if not is_finite(crit_multiplier) or crit_multiplier < 1.0:
		errors.append("crit_multiplier must be >= 1")
	return errors
