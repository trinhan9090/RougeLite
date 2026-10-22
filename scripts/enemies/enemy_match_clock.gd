class_name EnemyMatchClock
extends Node
## Authoritative match clock for the time-gated enemy roster.
##
## The clock lives in its own PROCESS_MODE_ALWAYS node so it keeps advancing
## while the SceneTree is paused for augment selection (the roster must not
## stall behind a level-up menu). It freezes on an explicit player pause and
## on a finished run, and it is only reset when a new run starts.
##
## The clock is deliberately independent from RunState.elapsed_simulation_seconds:
## that value stops while the tree is paused, the roster clock must not.

## Phases during which the roster clock must not advance.
const FROZEN_PHASES: Array[StringName] = [
	&"FOUNDATION", &"MENU", &"LOBBY", &"PAUSED", &"DEAD", &"GAME_OVER", &"RESTARTING",
]

var state: RunState
var running: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## Starts (or restarts) the clock for a run. The elapsed value is owned by the
## RunState, so a new run always starts from zero.
func begin(run_state: RunState) -> void:
	state = run_state
	running = true

func stop() -> void:
	running = false

func elapsed() -> float:
	return state.elapsed_match_seconds if state != null else 0.0

func _process(delta: float) -> void:
	if state == null or not running or not state.alive:
		return
	if FROZEN_PHASES.has(state.run_phase):
		return
	state.elapsed_match_seconds += delta
