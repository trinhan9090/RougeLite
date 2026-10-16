class_name SpawnDefinition
extends ContentDefinition

@export var period: float = 2.5
@export var exclusion_radius: float = 550.0
@export var max_distance: float = 950.0
@export var attempts: int = 30
@export var max_enemies: int = 110
@export var max_projectiles: int = 300
@export var initial_enemy_cap: int = 40
@export var cap_growth_per_level: int = 2

func validate() -> PackedStringArray:
	var errors := super.validate()
	if not is_finite(period) or period <= 0.0 or not is_finite(exclusion_radius) or exclusion_radius < 550.0 or not is_finite(max_distance) or max_distance < exclusion_radius or attempts < 1 or max_enemies < 1 or max_projectiles < 1:
		errors.append("%s: invalid spawn period/safety/budget" % id)
	return errors
