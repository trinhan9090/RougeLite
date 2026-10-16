class_name LevelManager
extends RefCounted

signal level_applied(level: int)
signal level_entered(level: int) # Domain unlock phase, always before offer phase.
var state: RunState
var curve: ProgressionDefinition
var awaiting_choice: bool = false

func _init(run_state: RunState, definition: ProgressionDefinition) -> void:
	state = run_state
	curve = definition

func add_xp(amount: int) -> void:
	if amount <= 0 or not state.alive:
		return
	if state.boss_gate_state in [&"PENDING",&"ACTIVE",&"DEFEATED",&"TRANSITIONING"]:
		state.xp_pending_during_boss += amount
		return
	state.current_xp += amount
	_apply_next()

func acknowledge_choice() -> bool:
	if not awaiting_choice or not state.alive:
		return false
	awaiting_choice = false
	_apply_next()
	return true

func _apply_next() -> void:
	if awaiting_choice or not state.alive or state.boss_gate_state != &"IDLE":
		return
	var needed: int = curve.threshold(state.current_level)
	if state.current_xp >= needed:
		state.current_xp -= needed
		state.current_level += 1
		awaiting_choice = true
		level_entered.emit(state.current_level)
		level_applied.emit(state.current_level)
