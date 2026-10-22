class_name TargetingService
extends RefCounted

static func intercept_point(origin: Vector2, target: Actor, speed: float) -> Vector2:
	var offset: Vector2 = target.hit_position() - origin
	var motion: Vector2 = target.velocity
	var a: float = motion.length_squared() - speed * speed
	var b: float = 2.0 * offset.dot(motion)
	var c: float = offset.length_squared()
	var time: float = -1.0
	if speed <= 0: return target.hit_position()
	if absf(a) < .0001:
		if absf(b) > .0001: time = -c / b
	else:
		var discriminant: float = b * b - 4.0 * a * c
		if discriminant >= 0:
			var first: float = (-b - sqrt(discriminant)) / (2.0 * a)
			var second: float = (-b + sqrt(discriminant)) / (2.0 * a)
			if first > 0: time = first
			if second > 0 and (time < 0 or second < time): time = second
	return target.hit_position() + motion * time if time > 0 else target.hit_position()

static func nearest(source: Actor, candidates: Array[Actor], range_px: float) -> Actor:
	if not is_instance_valid(source) or source.is_queued_for_deletion() or not source.health.is_alive() or range_px < 0.0:
		return null
	var selected: Actor
	var best_distance: float = range_px * range_px
	for candidate in candidates:
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion() or candidate == source or candidate.team == source.team or candidate.health == null or not candidate.health.is_alive():
			continue
		var distance: float = source.global_position.distance_squared_to(candidate.global_position)
		if distance > range_px * range_px:
			continue
		if selected == null or distance < best_distance or (distance == best_distance and candidate.actor_id < selected.actor_id):
			selected = candidate
			best_distance = distance
	return selected

## Skill target priority: nearest boss -> nearest enemies -> lowest HP among them.
## 1. Any living boss in range is always preferred (nearest boss wins).
## 2. Otherwise pick the closest enemy; enemies within NEAR_BAND_PX of that
##    closest distance count as "nearest", and the lowest-HP one is chosen.
##    Ties fall back to distance, then actor id.
const NEAR_BAND_PX: float = 48.0

static func priority(source: Actor, candidates: Array[Actor], range_px: float) -> Actor:
	if not is_instance_valid(source) or source.is_queued_for_deletion() or source.health == null or not source.health.is_alive() or range_px < 0.0:
		return null
	var in_range: Array[Actor] = []
	var nearest_squared: float = INF
	var nearest_boss: Actor = null
	var boss_squared: float = INF
	for candidate in candidates:
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion() or candidate == source or candidate.team == source.team or candidate.health == null or not candidate.health.is_alive():
			continue
		var distance: float = source.global_position.distance_squared_to(candidate.global_position)
		if distance > range_px * range_px:
			continue
		in_range.append(candidate)
		nearest_squared = minf(nearest_squared, distance)
		if candidate.is_boss and distance < boss_squared:
			nearest_boss = candidate
			boss_squared = distance
	if in_range.is_empty():
		return null
	if nearest_boss != null:
		return nearest_boss
	var band_end: float = sqrt(nearest_squared) + NEAR_BAND_PX
	var selected: Actor = null
	var selected_hp: float = INF
	var selected_distance: float = INF
	for candidate in in_range:
		var distance: float = source.global_position.distance_squared_to(candidate.global_position)
		if distance > band_end * band_end:
			continue
		var hp: float = candidate.health.current
		if selected == null or hp < selected_hp or (is_equal_approx(hp, selected_hp) and (distance < selected_distance or (distance == selected_distance and candidate.actor_id < selected.actor_id))):
			selected = candidate
			selected_hp = hp
			selected_distance = distance
	return selected

