class_name CombatProjectile
extends Node2D

var _combat: CombatService
var _source: WeakRef
var _target: WeakRef
var _rank: SkillRankDefinition
var _context: CombatContext
var _distance_left: float
var _direction: Vector2
var _steering: float = 0.0
var _legacy: bool = true
var _status: StatusEffectDefinition
var _hits: Dictionary[int, bool] = {}
var _excluded: Array[RID] = []
var projectile_id: int = 0
var _crit_pierce_applied: bool = false

func configure(combat: CombatService, source: Actor, target: Actor, rank: SkillRankDefinition, context: CombatContext) -> void:
	var origin: Vector2 = combat.cast_origin(source)
	configure_direction(combat, source, target, rank, context, origin.direction_to(TargetingService.intercept_point(origin,target,rank.projectile_speed)), 0.0, null)
	_legacy = true

func configure_direction(combat: CombatService, source: Actor, target: Actor, rank: SkillRankDefinition, context: CombatContext, direction: Vector2, steering: float, status: StatusEffectDefinition) -> void:
	_combat = combat
	_source = weakref(source)
	_target = weakref(target) if target != null else null
	_rank = rank.duplicate(true) as SkillRankDefinition
	_context = context
	projectile_id = context.budget.projectiles
	_distance_left = rank.range_px
	_direction = direction.normalized()
	_steering = steering
	_status = status
	_legacy = false
	_excluded = [source.get_rid()]

func _physics_process(delta: float) -> void:
	var source: Actor = _source.get_ref() as Actor
	var target: Actor = _target.get_ref() as Actor if _target != null else null
	if not is_instance_valid(source) or not source.health.is_alive() or _distance_left <= 0:
		queue_free()
		return
	if _legacy and (not is_instance_valid(target) or not target.health.is_alive()):
		queue_free()
		return
	if _steering > 0:
		if not is_instance_valid(target) or not target.health.is_alive() or _hits.has(target.actor_id):
			target = null
			var nearest: float = _distance_left * _distance_left
			for candidate: Actor in _combat.actors():
				if candidate.team == source.team or _hits.has(candidate.actor_id): continue
				var distance_sq: float = global_position.distance_squared_to(candidate.hit_position())
				if distance_sq < nearest:
					nearest = distance_sq
					target = candidate
			_target = weakref(target) if target != null else null
		if target != null:
			var desired: Vector2 = (target.hit_position() - global_position).normalized()
			_direction = desired if _legacy else _direction.rotated(clampf(_direction.angle_to(desired), -_steering * TAU * delta, _steering * TAU * delta))
	var distance: float = minf(_rank.projectile_speed * delta, _distance_left)
	if _legacy: distance = minf(distance, global_position.distance_to(target.hit_position()))
	var next: Vector2 = global_position + _direction * distance
	# A bounded sweep can pass through several colliders in one physics frame.
	for iteration in range(2 * (_rank.pierce_count + 2)):
		var query := PhysicsRayQueryParameters2D.create(global_position, next, (2|16 if source.team == 1 else 1|8) | 4)
		query.collide_with_areas=true
		# A moving target can enter the segment's starting point between ticks.
		query.hit_from_inside = true
		query.exclude = _excluded
		var collision: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
		if collision.is_empty(): break
		var receiver: Object=collision.collider
		var actor: Actor = receiver.actor if receiver is ActorHurtbox else receiver as Actor
		if receiver is Actor and is_instance_valid(actor.hurtbox):
			_excluded.append(actor.get_rid())
			continue
		if actor == null:
			queue_free()
			return
		_excluded.append(receiver.get_rid())
		if receiver is ActorHurtbox: _excluded.append(actor.get_rid())
		if actor==source or actor.team==source.team or not actor.health.is_alive(): continue
		if not _combat.unobstructed(global_position,actor.global_position):
			queue_free()
			return
		if not _hits.has(actor.actor_id):
			_hits[actor.actor_id] = true
			var result: DamageResult = _combat.hit(source, actor, _rank, _context, projectile_id, _status)
			if result.critical and _rank.behavior != null and not _crit_pierce_applied:
				_rank.pierce_count += _rank.behavior.crit_pierce
				_crit_pierce_applied = true
		if _hits.size() > _rank.pierce_count:
			queue_free()
			return
	global_position = next
	_distance_left -= distance
	rotation = _direction.angle()

func _draw() -> void:
	if get_meta("art_bound",false): return
	draw_line(Vector2(-12, 0), Vector2(4, 0), Color("b3f7ff"), 4)
	draw_circle(Vector2(4, 0), 3, Color.WHITE)
