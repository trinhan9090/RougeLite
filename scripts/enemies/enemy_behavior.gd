class_name EnemyBehavior
extends RefCounted
## One behaviour module drives one enemy archetype.
##
## Behaviour modules are pure gameplay: they read the actor, the combat service
## and the authored behaviour settings, and they never touch the network, never
## mutate shared resources and never award XP themselves. Damage always goes
## through CombatService, so the faction filter, hit immunity and the event
## budget stay shared with the player side.
##
## A behaviour is resolved from EnemyDefinition.behavior_id, never from a
## display name, so content stays data driven.

var actor: EnemyActor
var target: Actor
var _rank: SkillRankDefinition
var _retarget_left: float = 0.0

func setup(owner_actor: EnemyActor) -> void:
	actor = owner_actor
	_retarget_left = 0.0

## Called every physics tick while the actor is alive.
func tick(_delta: float) -> void:
	pass

## Steering intent in world space. The actor applies it.
func steering() -> Vector2:
	return Vector2.ZERO

# --- shared helpers --------------------------------------------------------

func settings() -> EnemyBehaviorSettings:
	return actor.behavior_settings if actor != null else null

func skill() -> SkillDefinition:
	return actor.attack_skill if actor != null else null

func skill_id() -> StringName:
	var definition := skill()
	return definition.id if definition != null else &"enemy.behaviour"

## Cached copy of the archetype's authored attack rank. The archetype damage
## ratio is applied here, so the authored skill always carries the basic
## enemy damage and the definition owns the comparison.
func skill_rank() -> SkillRankDefinition:
	if _rank == null:
		var definition := skill()
		if definition != null and definition.rank_scaling.size() > 0:
			_rank = definition.rank_scaling[0].duplicate(true) as SkillRankDefinition
		else:
			_rank = SkillRankDefinition.new()
		if actor != null and actor.definition != null:
			_rank.damage *= actor.definition.damage_multiplier
	return _rank

func move_speed() -> float:
	if actor == null:
		return 0.0
	return actor.stats.move_speed * actor.statuses.movement_factor()

func apply_movement(intent: Vector2) -> void:
	if actor == null:
		return
	MovementController.move(actor, intent, move_speed())

func current_target() -> Actor:
	if not is_instance_valid(target) or target.is_queued_for_deletion() or target.health == null or not target.health.is_alive():
		target = null
	return target

## Picks the closest living enemy of the opposing faction with a stable tie
## break on the actor id, so a team never flip-flops between two players.
func refresh_target(candidates: Array[Actor]) -> Actor:
	var best: Actor = null
	var best_distance: float = INF
	for candidate in candidates:
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
			continue
		if candidate.health == null or not candidate.health.is_alive():
			continue
		if actor != null and candidate.team == actor.team:
			continue
		var distance: float = actor.global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
		elif best != null and is_equal_approx(distance, best_distance) and candidate.actor_id < best.actor_id:
			best = candidate
			best_distance = distance
	target = best
	return best

## Retargets on the authored interval so several enemies do not all re-evaluate
## their target on the same frame.
func update_target(delta: float, candidates: Array[Actor]) -> Actor:
	_retarget_left -= delta
	if current_target() == null or _retarget_left <= 0.0:
		_retarget_left = maxf(0.1, settings().retarget_interval if settings() != null else 0.75)
		refresh_target(candidates)
	return current_target()

## Direction from the actor towards a point, used for aiming and telegraphs.
func direction_to(point: Vector2) -> Vector2:
	var offset := point - actor.global_position
	return offset.normalized() if offset.length_squared() > 0.0001 else Vector2.RIGHT

## True when nothing solid stands between the actor and the point.
func has_line_of_sight(point: Vector2) -> bool:
	if actor == null:
		return false
	var space := actor.get_world_2d().direct_space_state
	if space == null:
		return true
	var query := PhysicsRayQueryParameters2D.create(actor.global_position, point, 4)
	query.hit_from_inside = true
	query.exclude = [actor.get_rid()]
	return space.intersect_ray(query).is_empty()

## Applies the archetype damage to every eligible player inside a radius.
##
## CombatService owns the faction filter, so an enemy can never damage another
## enemy, and it applies at most one hit per target inside the area.
func damage_area(center: Vector2, radius: float, damage_scale: float = 1.0) -> int:
	var combat := actor.combat if actor != null else null
	if combat == null or radius <= 0.0:
		return 0
	var intent := CastIntent.new()
	intent.source_ref = weakref(actor)
	intent.rank = skill_rank().duplicate(true) as SkillRankDefinition
	intent.rank.damage *= maxf(0.0, damage_scale)
	intent.context = combat.next_context(actor, skill_id())
	intent.direction = direction_to(center)
	intent.aim_point = center
	var hit_ids: Dictionary[int, bool] = {}
	combat.radial_hit(intent, center, radius, hit_ids)
	return hit_ids.size()

## Applies the archetype damage to an explicit list of actors, one hit each.
func damage_targets(victims: Array[Actor], damage_scale: float = 1.0) -> int:
	var combat := actor.combat if actor != null else null
	if combat == null:
		return 0
	var rank := skill_rank().duplicate(true) as SkillRankDefinition
	rank.damage *= maxf(0.0, damage_scale)
	var context := combat.next_context(actor, skill_id())
	var hits := 0
	for victim in victims:
		if not is_instance_valid(victim) or victim.health == null or not victim.health.is_alive():
			continue
		if victim.team == actor.team:
			continue
		if combat.hit(actor, victim, rank, context).accepted:
			hits += 1
	return hits

## Plays one of the archetype's authored cues.
func play_cue(cue: StringName, volume_scale: float = 1.0) -> void:
	if actor == null or actor.audio == null:
		return
	actor.audio.play(actor.audio_profile, cue, actor.global_position, volume_scale)

## Shows a telegraph footprint. The visual is presentation only: the damage
## window is owned by the behaviour state machine.
func show_telegraph(style: StringName, center: Vector2, radius: float, duration: float, direction: Vector2 = Vector2.RIGHT, color: Color = Color.WHITE) -> EnemyTelegraph:
	if actor == null or actor.telegraph_layer == null:
		return null
	var telegraph := EnemyTelegraph.new()
	telegraph.style = style
	telegraph.radius = radius
	telegraph.length = radius
	telegraph.direction = direction
	telegraph.duration = maxf(0.05, duration)
	telegraph.tint = color
	actor.telegraph_layer.add_child(telegraph)
	telegraph.global_position = center
	return telegraph
