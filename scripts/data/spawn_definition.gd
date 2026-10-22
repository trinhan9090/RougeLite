class_name SpawnDefinition
extends ContentDefinition
## Spawn policy for the encounter roster.
##
## The time-tier tables drive the time-gated roster: the global normal-enemy
## cap and the spawn rate follow elapsed match seconds, never player level.
## The boss schedule is intentionally NOT described here.

## Interval between spawn opportunities. The encounter budget accumulator
## decides how many enemies each opportunity releases, so the cadence stays
## short and the release rate stays smooth.
@export var period: float = 0.25
@export var exclusion_radius: float = 550.0
@export var max_distance: float = 950.0
@export var attempts: int = 30
@export var max_enemies: int = 110
@export var max_projectiles: int = 300
@export var initial_enemy_cap: int = 40
@export var cap_growth_per_level: int = 2

@export_group("Time roster")
## Normal enemies per second at the start of the match.
@export var base_spawn_rate: float = 0.7
## Normal enemies per second reached after ramp_seconds.
@export var peak_spawn_rate: float = 2.2
## Match seconds needed to reach peak_spawn_rate (12 minutes).
@export var ramp_seconds: float = 720.0
## Tier boundaries in match seconds, ascending.
@export var time_tier_seconds: Array[float] = [0.0, 120.0, 240.0, 360.0, 540.0, 720.0]
## Global cap on normal enemies per tier, aligned with time_tier_seconds.
@export var time_tier_caps: Array[int] = [45, 55, 70, 85, 95, 110]
## Relative spawn mix per tier, aligned with time_tier_seconds. Each entry maps
## an enemy type id to its relative weight; weights are normalised at roll time
## and are never guaranteed quotas. Types missing from a tier fall back to
## EnemyDefinition.spawn_weight.
@export var tier_weights: Array[Dictionary] = []

@export_group("Difficulty")
## Match seconds between difficulty steps (one boss window).
@export var difficulty_step_seconds: float = 180.0
## Stat bonus added per difficulty step.
@export var difficulty_step_bonus: float = 0.06
## Upper bound for the accumulated difficulty multiplier.
@export var max_difficulty_multiplier: float = 3.0

func validate() -> PackedStringArray:
	var errors := super.validate()
	if not is_finite(period) or period <= 0.0 or not is_finite(exclusion_radius) or exclusion_radius < 550.0 or not is_finite(max_distance) or max_distance < exclusion_radius or attempts < 1 or max_enemies < 1 or max_projectiles < 1:
		errors.append("%s: invalid spawn period/safety/budget" % id)
	if not is_finite(base_spawn_rate) or base_spawn_rate <= 0.0 or not is_finite(peak_spawn_rate) or peak_spawn_rate <= 0.0:
		errors.append("%s: spawn rates must be finite and positive" % id)
	if not is_finite(ramp_seconds) or ramp_seconds <= 0.0:
		errors.append("%s: ramp_seconds must be finite and positive" % id)
	if time_tier_seconds.size() != time_tier_caps.size():
		errors.append("%s: time tier tables must have the same length" % id)
	if not tier_weights.is_empty() and tier_weights.size() != time_tier_seconds.size():
		errors.append("%s: tier_weights must have the same length as time_tier_seconds" % id)
	for tier in tier_weights:
		for key: Variant in tier.keys():
			var weight := float(tier[key])
			if not is_finite(weight) or weight < 0.0:
				errors.append("%s: tier weight for '%s' must be finite and non-negative" % [id, String(key)])
	for index in range(1, time_tier_seconds.size()):
		if time_tier_seconds[index] <= time_tier_seconds[index - 1]:
			errors.append("%s: time_tier_seconds must ascend" % id)
	for cap in time_tier_caps:
		if cap < 1:
			errors.append("%s: time tier caps must be positive" % id)
	if not is_finite(difficulty_step_seconds) or difficulty_step_seconds <= 0.0:
		errors.append("%s: difficulty_step_seconds must be finite and positive" % id)
	if not is_finite(difficulty_step_bonus) or difficulty_step_bonus < 0.0:
		errors.append("%s: difficulty_step_bonus must be finite and non-negative" % id)
	if not is_finite(max_difficulty_multiplier) or max_difficulty_multiplier < 1.0:
		errors.append("%s: max_difficulty_multiplier must be at least 1" % id)
	return errors
