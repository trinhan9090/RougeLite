class_name RunState
extends RefCounted
## Per-run domain state. Definition Resources are not stored or mutated here.

var seed: int
var content_version: String
var elapsed_simulation_seconds: float = 0.0
var current_level: int = 1
var current_xp: int = 0
var xp_pending_during_boss: int = 0
var stage_index: int = 0
var map_id: StringName
var boss_gate_state: StringName = &"IDLE"
var run_upgrades: Dictionary[StringName, int] = {}
var alive: bool = true
var reroll_tokens: int = 0
var run_phase: StringName = &"FOUNDATION"
var rng: RunRng

func _init(run_seed: int = 0, version: String = "foundation-v1") -> void:
	seed = run_seed
	content_version = version
	rng = RunRng.new(seed)

func debug_summary() -> String:
	return "Seed: %d | Content: %s | Phase: %s | Level: %d" % [seed, content_version, run_phase, current_level]
