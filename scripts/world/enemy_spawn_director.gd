class_name EnemySpawnDirector
extends RefCounted

static func population_cap(definition: SpawnDefinition, level: int) -> int:
	return mini(definition.max_enemies,maxi(1,definition.initial_enemy_cap + definition.cap_growth_per_level * maxi(0,level-1)))

static func sample(player: Vector2, visible: Rect2, arena: ArenaGeometry, definition: SpawnDefinition, rng: RandomNumberGenerator, existing: Array[Actor]) -> Variant:
	for attempt in range(definition.attempts):
		var angle: float = rng.randf_range(-PI, PI)
		var distance: float = rng.randf_range(definition.exclusion_radius, definition.max_distance)
		var candidate: Vector2 = player + Vector2.from_angle(angle) * distance
		if visible.grow(20).has_point(candidate) or not arena.spawn_clear(candidate, 16) or not arena.navigable(candidate):
			continue
		var clear: bool = true
		for actor in existing:
			if is_instance_valid(actor) and actor.global_position.distance_to(candidate) < 32:
				clear = false
				break
		if clear:
			return candidate
	return null
