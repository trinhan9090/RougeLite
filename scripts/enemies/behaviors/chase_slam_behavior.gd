class_name ChaseSlamBehavior
extends EnemyBehavior
## Iron Bulwark: a slow tank that telegraphs a heavy overhead slam.
##
## Contract (AGENTS E1): 0.55s anticipation, one slam, 1.7s recovery, melee
## damage 1.8x baseline, telegraph footprint identical to the damage area.
## The strike direction is locked when the wind-up starts, so the player can
## always step out of the marked area.

enum State { CHASE, WINDUP, RECOVER }

var state: int = State.CHASE
var _timer: float = 0.0
var _strike_center: Vector2 = Vector2.ZERO
var _strike_direction: Vector2 = Vector2.RIGHT

func tick(delta: float) -> void:
	match state:
		State.CHASE:
			_tick_chase(delta)
		State.WINDUP:
			_tick_windup(delta)
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
	var attack_range: float = config.attack_range_px if config != null else 70.0
	if distance <= attack_range:
		_begin_windup(direction)
		return
	apply_movement(direction)

func _begin_windup(direction: Vector2) -> void:
	var config := settings()
	var windup: float = config.windup_seconds if config != null else 0.55
	var strike_radius: float = config.strike_radius_px if config != null else 58.0
	var attack_range: float = config.attack_range_px if config != null else 70.0
	# The slam lands in front of the armour, so the footprint matches the
	# telegraph a player sees instead of hiding the real hit area behind the
	# body of a slow enemy.
	_strike_direction = direction
	_strike_center = actor.global_position + direction * (attack_range * 0.55)
	state = State.WINDUP
	_timer = windup
	actor.visual_state = &"windup"
	actor.facing_override = direction
	show_telegraph(&"slam", _strike_center, strike_radius, windup, direction, Color(1.0, 0.55, 0.16, 0.55))
	play_cue(&"windup")

func _tick_windup(delta: float) -> void:
	apply_movement(Vector2.ZERO)
	_timer -= delta
	if _timer > 0.0:
		return
	state = State.RECOVER
	_timer = settings().recovery_seconds if settings() != null else 1.7
	actor.visual_state = &"attack"
	actor.facing_override = Vector2.ZERO
	var config := settings()
	var strike_radius: float = config.strike_radius_px if config != null else 58.0
	damage_area(_strike_center, strike_radius)
	play_cue(&"attack")

func _tick_recover(delta: float) -> void:
	apply_movement(Vector2.ZERO)
	_timer -= delta
	if _timer > 0.0:
		return
	state = State.CHASE
	actor.visual_state = &""
