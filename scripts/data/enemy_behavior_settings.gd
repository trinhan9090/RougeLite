class_name EnemyBehaviorSettings
extends Resource
## Numbers that describe how one enemy archetype fights.
##
## One superset resource serves all archetypes so the behaviour modules stay
## generic (no per-archetype branching inside shared code). Fields that an
## archetype does not use stay at their defaults.

@export_group("Timing")
## Anticipation window before the strike resolves (Bulwark 0.55s).
@export var windup_seconds: float = 0.0
## Lockout after an attack resolves (Bulwark 1.7s).
@export var recovery_seconds: float = 0.0
## Delay between the telegraph appearing and the AoE resolving (Ritualist 1.25s).
@export var telegraph_seconds: float = 0.0
## Countdown before a proximity blast (Bomber 0.8s).
@export var prime_seconds: float = 0.0
## Aim/charge window before a projectile is released (Marksman 0.4s).
@export var aim_seconds: float = 0.0

@export_group("Ranges")
## Distance at which the archetype is allowed to attack.
@export var attack_range_px: float = 32.0
## Radius of the damage footprint. It must match the telegraph and the collider.
@export var strike_radius_px: float = 40.0
## Radius of the explosion / ground AoE.
@export var blast_radius_px: float = 0.0
## Projectile travel speed in pixels per second.
@export var projectile_speed: float = 0.0
## Distance a ranged archetype tries to keep from its target.
@export var hold_distance_px: float = 0.0
## Below this distance a ranged archetype retreats instead of firing.
@export var retreat_distance_px: float = 0.0
## Maximum engagement distance; 0 means unlimited.
@export var max_engagement_range_px: float = 0.0
## Distance covered by a single lunge (Skitter).
@export var lunge_distance_px: float = 0.0
## How long the lunge itself lasts (Skitter). The dash speed is derived from
## the distance and this window, and is additionally clamped per tick.
@export var lunge_seconds: float = 0.16
## Distance at which a proximity archetype starts priming (Bomber).
@export var trigger_radius_px: float = 0.0
## Minimum distance kept from living players when spawning. Must be at least
## 1.5x the blast radius so nobody spawns inside a hazard.
@export var safe_spawn_radius_px: float = 0.0

@export_group("Targeting")
## How often the archetype re-evaluates its target (Bulwark 0.75s).
@export var retarget_interval: float = 0.75

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for field: StringName in [&"windup_seconds", &"recovery_seconds", &"telegraph_seconds", &"prime_seconds",
			&"aim_seconds", &"attack_range_px", &"strike_radius_px", &"blast_radius_px", &"projectile_speed",
			&"hold_distance_px", &"retreat_distance_px", &"max_engagement_range_px", &"lunge_distance_px",
			&"lunge_seconds", &"trigger_radius_px", &"safe_spawn_radius_px", &"retarget_interval"]:
		var value: float = get(field)
		if not is_finite(value) or value < 0.0:
			errors.append("enemy behaviour settings: %s must be finite and non-negative" % field)
	if strike_radius_px <= 0.0:
		errors.append("enemy behaviour settings: strike_radius_px must be positive")
	if blast_radius_px > 0.0 and safe_spawn_radius_px < blast_radius_px * 1.5:
		errors.append("enemy behaviour settings: safe_spawn_radius_px must be >= 1.5x blast_radius_px")
	if blast_radius_px > 0.0 and trigger_radius_px > 0.0 and trigger_radius_px < blast_radius_px:
		errors.append("enemy behaviour settings: trigger_radius_px must cover the blast radius")
	if max_engagement_range_px > 0.0 and attack_range_px > max_engagement_range_px:
		errors.append("enemy behaviour settings: attack_range_px exceeds max_engagement_range_px")
	return errors
