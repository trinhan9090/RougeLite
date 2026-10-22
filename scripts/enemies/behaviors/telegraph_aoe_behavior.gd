class_name TelegraphAoeBehavior
extends EnemyBehavior
## Cinder Ritualist: a ranged caster that marks a patch of ground and detonates
## it after a visible delay.
##
## Contract (AGENTS E4): the marked position is a snapshot taken when the cast
## starts and never homes afterwards, the telegraph radius is exactly the
## damage radius, every eligible player is hit at most once per cast, and the
## marked centre never lands inside solid map geometry.

enum State { REPOSITION, CAST, RECOVER }

var state: int = State.REPOSITION
var _timer: float = 0.0
var _cast_center: Vector2 = Vector2.ZERO
var _cast_id: int = 0

func tick(delta: float) -> void:
	match state:
		State.REPOSITION:
			_tick_reposition(delta)
		State.CAST:
			_tick_cast(delta)
		State.RECOVER:
			_tick_recover(delta)

func _tick_reposition(delta: float) -> void:
	var goal := update_target(delta, actor.candidate_targets())
	if goal == null:
		apply_movement(Vector2.ZERO)
		return
	var config := settings()
	var attack_range: float = config.attack_range_px if config != null else 240.0
	var hold_distance: float = config.hold_distance_px if config != null else 150.0
	var offset: Vector2 = goal.global_position - actor.global_position
	var distance := offset.length()
	var direction := offset.normalized() if distance > 0.001 else Vector2.RIGHT
	if distance < hold_distance:
		apply_movement(-direction)
		return
	if distance > attack_range:
		apply_movement(direction)
		return
	apply_movement(Vector2.ZERO)
	_begin_cast(goal.global_position)

func _begin_cast(target_position: Vector2) -> void:
	var config := settings()
	var telegraph_seconds: float = config.telegraph_seconds if config != null else 1.25
	var blast_radius: float = config.blast_radius_px if config != null else 96.0
	_cast_center = _valid_center(target_position, blast_radius)
	_cast_id += 1
	state = State.CAST
	_timer = telegraph_seconds
	actor.visual_state = &"windup"
	actor.facing_override = direction_to(_cast_center)
	show_telegraph(&"rune", _cast_center, blast_radius, telegraph_seconds, Vector2.ZERO, Color(1.0, 0.45, 0.12, 0.7))
	play_cue(&"warning")

func _valid_center(target_position: Vector2, blast_radius: float) -> Vector2:
	var arena := actor.arena
	if arena == null:
		return target_position
	if arena.spawn_clear(target_position, maxf(8.0, blast_radius * 0.35)):
		return target_position
	if arena.spawn_clear(actor.global_position, maxf(8.0, blast_radius * 0.35)):
		return actor.global_position
	return target_position

func _tick_cast(delta: float) -> void:
	apply_movement(Vector2.ZERO)
	_timer -= delta
	if _timer > 0.0:
		return
	var config := settings()
	var blast_radius: float = config.blast_radius_px if config != null else 96.0
	damage_area(_cast_center, blast_radius)
	play_cue(&"attack")
	state = State.RECOVER
	_timer = config.recovery_seconds if config != null else 3.75
	actor.visual_state = &"attack"
	actor.facing_override = Vector2.ZERO

func _tick_recover(delta: float) -> void:
	apply_movement(Vector2.ZERO)
	_timer -= delta
	if _timer > 0.0:
		return
	state = State.REPOSITION
	actor.visual_state = &""
