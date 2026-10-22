class_name LungeMeleeBehavior
extends EnemyBehavior
## Razor Skitter: a fast, fragile melee unit that closes the gap with a short
## lunging strike.
##
## Contract (AGENTS E2): 0.22s crouch, one lunge of bounded length, one strike,
## 1.2s recovery, damage 0.70x baseline. The lunge is clamped and never
## tunnels through solid geometry, and it applies its damage exactly once.

enum State { CHASE, WINDUP, LUNGE, RECOVER }

## Hard limit on how far one physics tick may travel during the lunge, so a
## fast dash can never step through a thin wall.
const MAX_LUNGE_STEP_PX: float = 10.0

var state: int = State.CHASE
var _timer: float = 0.0
var _lunge_direction: Vector2 = Vector2.RIGHT
var _lunge_left: float = 0.0

func tick(delta: float) -> void:
	match state:
		State.CHASE:
			_tick_chase(delta)
		State.WINDUP:
			_tick_windup(delta)
		State.LUNGE:
			_tick_lunge(delta)
		State.RECOVER:
			_tick_recover(delta)

func _tick_chase(delta: float) -> void:
	var goal := update_target(delta, actor.candidate_targets())
	if goal == null:
		apply_movement(Vector2.ZERO)
		return
	var offset: Vector2 = goal.global_position - actor.global_position
	var distance := offset.length()
	var direction := offset.normalized() if distance > 0.001 else Vector2.RIGHT
	var config := settings()
	var attack_range: float = config.attack_range_px if config != null else 46.0
	if distance <= attack_range:
		_begin_windup(direction)
		return
	apply_movement(direction)

func _begin_windup(direction: Vector2) -> void:
	var config := settings()
	var windup: float = config.windup_seconds if config != null else 0.22
	var strike_radius: float = config.strike_radius_px if config != null else 34.0
	_lunge_direction = direction
	state = State.WINDUP
	_timer = windup
	actor.visual_state = &"windup"
	actor.facing_override = direction
	show_telegraph(&"streak", actor.global_position + direction * (config.lunge_distance_px if config != null else 120.0) * 0.5, strike_radius * 0.9, windup, direction, Color(0.35, 0.95, 1.0, 0.45))
	play_cue(&"windup")

func _tick_windup(delta: float) -> void:
	apply_movement(Vector2.ZERO)
	_timer -= delta
	if _timer > 0.0:
		return
	var config := settings()
	var distance: float = config.lunge_distance_px if config != null else 120.0
	_lunge_left = distance
	state = State.LUNGE
	_timer = config.lunge_seconds if config != null else 0.16
	actor.visual_state = &"attack"

func _tick_lunge(delta: float) -> void:
	var config := settings()
	var duration: float = config.lunge_seconds if config != null else 0.16
	var speed: float = (_lunge_left / maxf(0.01, duration)) if duration > 0.0 else 0.0
	speed = minf(speed, MAX_LUNGE_STEP_PX * 60.0)
	apply_movement(_lunge_direction * speed)
	_lunge_left = maxf(0.0, _lunge_left - speed * delta)
	_timer -= delta
	if _timer > 0.0 and _lunge_left > 0.0:
		return
	_resolve_strike()

func _resolve_strike() -> void:
	var config := settings()
	var strike_radius: float = config.strike_radius_px if config != null else 34.0
	var victims: Array[Actor] = []
	for candidate in actor.candidate_targets():
		if not is_instance_valid(candidate) or candidate.health == null or not candidate.health.is_alive():
			continue
		if candidate.team == actor.team:
			continue
		if actor.global_position.distance_to(candidate.global_position) <= strike_radius:
			victims.append(candidate)
	damage_targets(victims)
	play_cue(&"attack")
	state = State.RECOVER
	_timer = config.recovery_seconds if config != null else 1.2
	actor.visual_state = &""

func _tick_recover(delta: float) -> void:
	apply_movement(Vector2.ZERO)
	_timer -= delta
	if _timer > 0.0:
		return
	state = State.CHASE
