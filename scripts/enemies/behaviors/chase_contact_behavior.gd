class_name ChaseContactBehavior
extends EnemyBehavior
## The basic enemy: walk straight at the target and deal contact damage.
##
## The steering below reproduces the legacy inline behaviour of the basic
## enemy one to one, including the shared flow field lookup and the stop
## distance, so the early game feel does not change.

const STOP_DISTANCE: float = 26.0
## Bosses stop further away, exactly like the legacy inline steering did.
const BOSS_STOP_DISTANCE: float = 44.0

func tick(_delta: float) -> void:
	var goal := actor.legacy_target()
	if goal == null:
		actor.velocity = Vector2.ZERO
		return
	var stop_distance: float = BOSS_STOP_DISTANCE if actor.is_boss else STOP_DISTANCE
	var offset: Vector2 = goal.global_position - actor.global_position
	var direction: Vector2 = offset.normalized() if offset.length() > stop_distance else Vector2.ZERO
	if direction != Vector2.ZERO and actor.navigation.is_valid():
		# The arena caches the shared flow field; steering must still use the
		# current body position every physics tick to avoid overshooting turns.
		direction = actor.navigation.call(actor.global_position, goal.global_position)
	apply_movement(direction)
