class_name MatchClockAuthority
extends Node
## Host-authoritative match clock for survival scoring.
## Tick-driven simulation time; frozen at GAME_OVER.

signal clock_updated(elapsed_seconds: float)
signal match_started()
signal match_ended(final_time: float)

const TICK_RATE: int = 60  # Physics ticks per second

var _is_running: bool = false
var _elapsed_ticks: int = 0
var _match_start_time: int = 0
var _match_end_time: int = 0

func start_match() -> void:
	if not multiplayer.is_server():
		push_error("MatchClockAuthority: Only server can start match")
		return

	_is_running = true
	_elapsed_ticks = 0
	_match_start_time = Time.get_ticks_msec()
	_match_end_time = 0

	match_started.emit()
	print("MatchClockAuthority: Match started")

	# Broadcast to clients
	rpc("_client_receive_match_start")

@rpc("authority", "reliable")
func _client_receive_match_start() -> void:
	_is_running = true
	_elapsed_ticks = 0

func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server():
		return

	if _is_running:
		_elapsed_ticks += 1

		# Broadcast time periodically (every second)
		if _elapsed_ticks % TICK_RATE == 0:
			var elapsed_seconds := get_elapsed_seconds()
			clock_updated.emit(elapsed_seconds)
			rpc("_client_receive_clock_update", elapsed_seconds)

func end_match() -> void:
	if not multiplayer.is_server():
		return

	if not _is_running:
		return

	_is_running = false
	_match_end_time = Time.get_ticks_msec()
	var final_time := get_elapsed_seconds()

	match_ended.emit(final_time)
	print("MatchClockAuthority: Match ended at %02d:%02d" % [int(final_time) / 60, int(final_time) % 60])

	# Broadcast to clients
	rpc("_client_receive_match_end", final_time)

@rpc("authority", "reliable")
func _client_receive_match_end(final_time: float) -> void:
	_is_running = false

@rpc("authority", "unreliable_ordered")
func _client_receive_clock_update(elapsed_seconds: float) -> void:
	# Client updates HUD display
	clock_updated.emit(elapsed_seconds)

func get_elapsed_ticks() -> int:
	return _elapsed_ticks

func get_elapsed_seconds() -> float:
	return _elapsed_ticks / float(TICK_RATE)

func get_formatted_time() -> String:
	var seconds := get_elapsed_seconds()
	var minutes := int(seconds) / 60
	var secs := int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]

func is_running() -> bool:
	return _is_running

func reset() -> void:
	_is_running = false
	_elapsed_ticks = 0
	_match_start_time = 0
	_match_end_time = 0
