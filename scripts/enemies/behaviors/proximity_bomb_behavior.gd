class_name ProximityBombBehavior
extends EnemyBehavior
## Volatile Husk: a melee unit that primes and detonates next to its target.
##
## Contract (AGENTS E5): the blast is primed for 0.8s with a visible countdown,
## it resolves exactly once, it only hits living players of the opposing
## faction, and dying during the prime cancels the blast.

enum State { CHASE, PRIMING }

## Minimum lifetime before the husk may start priming, so it can never appear
## already armed on top of a player.
const SPAWN_GRACE_SECONDS: float = 0.6

var state: int = State.CHASE
var _timer: float = 0.0
var _grace_left: float = SPAWN_GRACE_SECONDS
var _beep_left: float = 0.0

func tick(delta: float) -> void:
	match state:
		State.CHASE:
			_tick_chase(delta)
		State.PRIMING:
			_tick_priming(delta)

func _tick_chase(delta: float) -> void:
	_grace_left = maxf(0.0, _grace_left - delta)
	var goal := update_target(delta, actor.candidate_targets())
	if goal == null:
		apply_movement(Vector2.ZERO)
		return
	var config := settings()
	var trigger_radius: float = config.trigger_radius_px if config != null else 110.0
	var offset: Vector2 = goal.global_position - actor.global_position
	var distance := offset.length()
	var direction := offset.normalized() if distance > 0.001 else Vector2.RIGHT
	if _grace_left <= 0.0 and distance <= trigger_radius:
		_begin_prime()
		return
	apply_movement(direction)

func _begin_prime() -> void:
	var config := settings()
	var prime_seconds: float = config.prime_seconds if config != null else 0.8
	var blast_radius: float = config.blast_radius_px if config != null else 110.0
	state = State.PRIMING
	_timer = prime_seconds
	_beep_left = 0.0
	actor.visual_state = &"windup"
	show_telegraph(&"danger", actor.global_position, blast_radius, prime_seconds, Vector2.ZERO, Color(0.78, 0.95, 0.2, 0.85))

func _tick_priming(delta: float) -> void:
	apply_movement(Vector2.ZERO)
	_timer -= delta
	_beep_left -= delta
	if _beep_left <= 0.0:
		# The beep accelerates while the charge builds.
		var remaining: float = maxf(0.0, _timer)
		_beep_left = maxf(0.08, remaining * 0.3)
		play_cue(&"warning", 0.8)
	if _timer > 0.0:
		return
	_explode()

func _explode() -> void:
	var config := settings()
	var blast_radius: float = config.blast_radius_px if config != null else 110.0
	damage_area(actor.global_position, blast_radius)
	play_cue(&"attack")
	actor.visual_state = &"attack"
	# The husk ends through the normal death lifecycle, so the kill is worth
	# exactly one experience orb and never two.
	actor.self_destruct()
