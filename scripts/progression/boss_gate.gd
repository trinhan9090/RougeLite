class_name BossGate
extends RefCounted
var state: RunState
var completed: Dictionary[int,bool] = {}
var milestone: int = 0
func _init(run_state: RunState) -> void: state = run_state
func request(level: int) -> bool:
	if not state.alive or level < 10 or level % 10 != 0 or completed.has(level) or state.boss_gate_state != &"IDLE": return false
	milestone = level
	state.boss_gate_state = &"PENDING"
	return true
func activate() -> bool:
	if not state.alive or state.boss_gate_state != &"PENDING": return false
	state.boss_gate_state = &"ACTIVE"
	return true
func defeat() -> bool:
	if not state.alive or state.boss_gate_state != &"ACTIVE": return false
	completed[milestone] = true
	state.boss_gate_state = &"DEFEATED"
	return true
func finish_transition() -> bool:
	if not state.alive or state.boss_gate_state != &"TRANSITIONING": return false
	state.boss_gate_state = &"IDLE"
	return true
