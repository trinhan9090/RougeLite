class_name TimeEncounterDirector
extends Node
## Host-authoritative strict 180-second boss spawn cadence.
## Spawns exactly one new boss at each 3-minute boundary regardless of active bosses.

signal boss_spawn_scheduled(boss_sequence: int, scheduled_tick: int)
signal boss_spawned(boss_id: String, boss_sequence: int, elapsed_time: float)
signal boss_defeated(boss_id: String, boss_sequence: int)

const BOSS_SPAWN_INTERVAL_SECONDS: float = 180.0
const TICK_RATE: int = 60  # Physics ticks per second

var _match_elapsed_ticks: int = 0
var _next_boss_sequence: int = 1
var _last_processed_tick: int = 0
var _active_bosses: Dictionary = {}  # boss_id → BossState
var _defeated_boss_ids: Array[String] = []

class BossState:
	var boss_id: String
	var boss_sequence: int
	var spawned_tick: int
	var type: StringName
	var node: Node = null
	var is_alive: bool = true
	var current_hp: int = 100
	var max_hp: int = 100

func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server():
		return

	_match_elapsed_ticks += 1

	# Check for boss spawn boundaries
	_check_boss_spawn_schedule()

func _check_boss_spawn_schedule() -> void:
	var spawn_interval_ticks := int(BOSS_SPAWN_INTERVAL_SECONDS * TICK_RATE)

	# Calculate which boss should exist by now
	var expected_boss_sequence := 1 + (_match_elapsed_ticks / spawn_interval_ticks)

	# Spawn all missed bosses (catch-up for lag/freeze)
	while _next_boss_sequence <= expected_boss_sequence:
		var scheduled_tick := (_next_boss_sequence - 1) * spawn_interval_ticks
		if scheduled_tick > _last_processed_tick:
			_spawn_boss_at_sequence(_next_boss_sequence, scheduled_tick)
			_last_processed_tick = scheduled_tick
		_next_boss_sequence += 1

func _spawn_boss_at_sequence(boss_sequence: int, scheduled_tick: int) -> void:
	var run_id := _get_run_id()  # TODO: Get from match state
	var boss_id := "%s_boss_%d" % [run_id, boss_sequence]

	# Prevent duplicate spawn
	if _active_bosses.has(boss_id) or boss_id in _defeated_boss_ids:
		return

	var boss := BossState.new()
	boss.boss_id = boss_id
	boss.boss_sequence = boss_sequence
	boss.spawned_tick = _match_elapsed_ticks
	boss.type = _select_boss_type(boss_sequence)

	_active_bosses[boss_id] = boss

	var elapsed_time := _match_elapsed_ticks / float(TICK_RATE)
	boss_spawned.emit(boss_id, boss_sequence, elapsed_time)

	print("TimeEncounterDirector: Spawned boss #%d at %02d:%02d (%d ticks)" % [
		boss_sequence,
		int(elapsed_time) / 60,
		int(elapsed_time) % 60,
		_match_elapsed_ticks
	])

	# Broadcast to clients
	rpc("_client_receive_boss_spawn", boss_id, boss_sequence, boss.type, elapsed_time)

@rpc("authority", "reliable")
func _client_receive_boss_spawn(boss_id: String, boss_sequence: int, boss_type: StringName, elapsed_time: float) -> void:
	# Client spawns boss visual
	# TODO: Integrate with existing boss spawner
	pass

func _select_boss_type(boss_sequence: int) -> StringName:
	# Cycle through available bosses
	var boss_types: Array[StringName] = [&"stone_warden", &"ember_sentinel"]
	var index := (boss_sequence - 1) % boss_types.size()
	return boss_types[index]

func report_boss_death(boss_id: String) -> void:
	if not multiplayer.is_server():
		return

	var boss := _active_bosses.get(boss_id) as BossState
	if boss == null:
		return

	if not boss.is_alive:
		return  # Already dead, prevent duplicate

	boss.is_alive = false
	_active_bosses.erase(boss_id)
	_defeated_boss_ids.append(boss_id)

	boss_defeated.emit(boss_id, boss.boss_sequence)

	print("TimeEncounterDirector: Boss #%d defeated (id: %s)" % [boss.boss_sequence, boss_id])

	# Broadcast to clients
	rpc("_client_receive_boss_death", boss_id, boss.boss_sequence)

@rpc("authority", "reliable")
func _client_receive_boss_death(boss_id: String, boss_sequence: int) -> void:
	# Client plays boss death effects
	# TODO: Integrate with existing boss system
	pass

func get_active_boss_count() -> int:
	return _active_bosses.size()

func get_defeated_boss_count() -> int:
	return _defeated_boss_ids.size()

func get_next_boss_spawn_time() -> float:
	var spawn_interval_ticks := int(BOSS_SPAWN_INTERVAL_SECONDS * TICK_RATE)
	var next_spawn_tick := _next_boss_sequence * spawn_interval_ticks
	return next_spawn_tick / float(TICK_RATE)

func get_elapsed_time() -> float:
	return _match_elapsed_ticks / float(TICK_RATE)

func _get_run_id() -> String:
	# TODO: Get from match state
	return "run_%d" % Time.get_ticks_msec()

func reset() -> void:
	_match_elapsed_ticks = 0
	_next_boss_sequence = 1
	_last_processed_tick = 0
	_active_bosses.clear()
	_defeated_boss_ids.clear()
