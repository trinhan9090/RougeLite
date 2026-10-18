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
