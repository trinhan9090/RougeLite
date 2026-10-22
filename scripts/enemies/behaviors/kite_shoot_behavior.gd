class_name KiteShootBehavior
extends EnemyBehavior
## Hollow Marksman: a ranged unit that keeps its distance and fires one
## committed projectile per cycle.
##
## Contract (AGENTS E3): 0.4s aim with a visible direction, exactly one
## projectile, walls block the shot, retreat when the player closes in, and no
## shot when the line of sight is blocked. The aim direction is locked when the
## telegraph appears, so the line the player sees is the line the shot takes.

enum State { REPOSITION, AIM, RECOVER }

var state: int = State.REPOSITION
var _timer: float = 0.0
var _aim_direction: Vector2 = Vector2.RIGHT
var _strafe_sign: float = 1.0

func tick(delta: float) -> void:
	match state:
		State.REPOSITION:
			_tick_reposition(delta)
		State.AIM:
			_tick_aim(delta)
		State.RECOVER:
			_tick_recover(delta)

func _tick_reposition(delta: float) -> void:
	var goal := update_target(delta, actor.candidate_targets())
	if goal == null:
		apply_movement(Vector2.ZERO)
		return
	var config := settings()
	var attack_range: float = config.attack_range_px if config != null else 260.0
	var hold_distance: float = config.hold_distance_px if config != null else 180.0
	var retreat_distance: float = config.retreat_distance_px if config != null else 110.0
	var max_range: float = config.max_engagement_range_px if config != null else 420.0
	var offset: Vector2 = goal.global_position - actor.global_position
	var distance := offset.length()
	var direction := offset.normalized() if distance > 0.001 else Vector2.RIGHT
	var clear := has_line_of_sight(goal.global_position)
	if distance > max_range or not clear:
		# Out of reach or blocked: close the gap instead of shooting through
		# a wall.
		apply_movement(direction)
		return
	if distance < retreat_distance:
		apply_movement(-direction)
		return
	if distance > attack_range:
		apply_movement(direction)
		return
	# Inside the standoff band: orbit slowly so the unit is never a static
	# target, and keep the aim window honest.
	var tangent := direction.orthogonal() * _strafe_sign
	apply_movement(tangent * 0.6)
	if _strafe_sign > 0.0 and _timer <= 0.0:
		_strafe_sign = -1.0
		_timer = 2.4
	elif _strafe_sign < 0.0 and _timer <= 0.0:
		_strafe_sign = 1.0
		_timer = 2.4
	_timer -= delta
	_begin_aim(direction, max_range)

func _begin_aim(direction: Vector2, max_range: float) -> void:
	var config := settings()
	var aim_seconds: float = config.aim_seconds if config != null else 0.4
	_aim_direction = direction
	state = State.AIM
	_timer = aim_seconds
	actor.visual_state = &"windup"
	actor.facing_override = direction
	show_telegraph(&"aim", actor.global_position, max_range, aim_seconds, direction, Color(0.72, 0.36, 1.0, 0.85))
	play_cue(&"windup")

func _tick_aim(delta: float) -> void:
	apply_movement(Vector2.ZERO)
	_timer -= delta
	if _timer > 0.0:
		return
	_fire()
	state = State.RECOVER
	_timer = settings().recovery_seconds if settings() != null else 1.8
	actor.visual_state = &"attack"
	actor.facing_override = Vector2.ZERO

func _fire() -> void:
	var combat := actor.combat
	if combat == null:
		return
	var rank := skill_rank().duplicate(true) as SkillRankDefinition
	if rank.projectile_speed <= 0.0:
		return
	var intent := CastIntent.new()
	intent.source_ref = weakref(actor)
	intent.target_ref = weakref(target) if target != null else null
	intent.rank = rank
	intent.context = combat.next_context(actor, skill_id())
	intent.direction = _aim_direction
	if combat.emit_projectile(intent, _aim_direction, 1.0, null):
		play_cue(&"attack")

func _tick_recover(delta: float) -> void:
	apply_movement(Vector2.ZERO)
	_timer -= delta
	if _timer > 0.0:
		return
	state = State.REPOSITION
	actor.visual_state = &""
