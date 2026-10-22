class_name EnemySpawnDirector
extends RefCounted
## Spawn sampling and the time-based roster policy.
##
## The level based population_cap() is the legacy adaptive cap and stays
## untouched (boss summons and existing fixtures depend on it). The time_*
## helpers implement the roster policy: the cap, the spawn rate and the
## difficulty multiplier follow elapsed match seconds, never the player level.

static func population_cap(definition: SpawnDefinition, level: int) -> int:
	return mini(definition.max_enemies,maxi(1,definition.initial_enemy_cap + definition.cap_growth_per_level * maxi(0,level-1)))

## Index of the time tier that contains the given match second.
static func time_tier_index(definition: SpawnDefinition, elapsed_seconds: float) -> int:
	if definition.time_tier_seconds.is_empty():
		return 0
	var index := 0
	for tier in range(definition.time_tier_seconds.size()):
		if elapsed_seconds >= definition.time_tier_seconds[tier]:
			index = tier
	return index

## Global cap on living normal enemies for the given match second.
static func time_population_cap(definition: SpawnDefinition, elapsed_seconds: float) -> int:
	if definition.time_tier_caps.is_empty():
		return definition.max_enemies
	var index := time_tier_index(definition, elapsed_seconds)
	if index < 0 or index >= definition.time_tier_caps.size():
		return definition.time_tier_caps[0]
	return definition.time_tier_caps[index]

## Normal enemies per second for the given match second. The ramp is linear so
## a tier change never produces a spike.
static func time_spawn_rate(definition: SpawnDefinition, elapsed_seconds: float) -> float:
	var ramp := clampf(elapsed_seconds / maxf(1.0, definition.ramp_seconds), 0.0, 1.0)
	return lerpf(definition.base_spawn_rate, definition.peak_spawn_rate, ramp)

## Time based difficulty multiplier. The recommended starter formula is
## 1 + bonus per difficulty window; it is capped so late matches stay playable.
static func time_difficulty_multiplier(definition: SpawnDefinition, elapsed_seconds: float) -> float:
	if definition.difficulty_step_seconds <= 0.0:
		return 1.0
	var steps := floorf(maxf(0.0, elapsed_seconds) / definition.difficulty_step_seconds)
	return minf(definition.max_difficulty_multiplier, 1.0 + definition.difficulty_step_bonus * steps)

static func sample(player: Vector2, visible: Rect2, arena: ArenaGeometry, definition: SpawnDefinition, rng: RandomNumberGenerator, existing: Array[Actor], min_radius: float = 0.0) -> Variant:
	return sample_safe(player, [player], min_radius, visible, arena, definition, rng, existing)

## Samples a spawn point that keeps the safe distance from every listed
## player, so a proximity archetype never appears inside a hazard.
static func sample_safe(origin: Vector2, avoid: Array[Vector2], min_radius: float, visible: Rect2, arena: ArenaGeometry, definition: SpawnDefinition, rng: RandomNumberGenerator, existing: Array[Actor]) -> Variant:
	var floor_radius := maxf(definition.exclusion_radius, min_radius)
	for attempt in range(definition.attempts):
		var angle: float = rng.randf_range(-PI, PI)
		var distance: float = rng.randf_range(floor_radius, maxf(floor_radius + 1.0, definition.max_distance))
		var candidate: Vector2 = origin + Vector2.from_angle(angle) * distance
		if visible.grow(20).has_point(candidate) or not arena.spawn_clear(candidate, 16) or not arena.navigable(candidate):
			continue
		var unsafe := false
		for point in avoid:
			if point.distance_to(candidate) < floor_radius:
				unsafe = true
				break
		if unsafe:
			continue
		var clear: bool = true
		for actor in existing:
			if is_instance_valid(actor) and actor.global_position.distance_to(candidate) < 32:
				clear = false
				break
		if clear:
			return candidate
	return null
