class_name NetworkDiagnostics
extends Node
## Network performance and stability diagnostics.

signal ping_received(rtt_ms: float)
signal packet_loss_reported(loss_percent: float)

var _ping_start_time: float = 0.0
var _rtt_history: Array[float] = []
var _max_rtt_history_size: int = 60
var _ping_sequence: int = 0

func start_ping() -> void:
	_ping_sequence += 1
	_ping_start_time = Time.get_ticks_msec() / 1000.0
	rpc_id(1, "_receive_ping", _ping_sequence, _ping_start_time)

@rpc("any_peer", "reliable")
func _receive_ping(seq: int, send_time: float) -> void:
	rpc_id(multiplayer.get_remote_sender_id(), "_receive_pong", seq, send_time)

@rpc("any_peer", "reliable")
func _receive_pong(seq: int, send_time: float) -> void:
	var rtt_ms: float = ((Time.get_ticks_msec() / 1000.0) - send_time) * 1000.0
	_rtt_history.append(rtt_ms)
	if _rtt_history.size() > _max_rtt_history_size:
		_rtt_history.pop_front()
	ping_received.emit(rtt_ms)

func get_average_rtt_ms() -> float:
	if _rtt_history.is_empty():
		return 0.0
	var sum: float = 0.0
	for rtt in _rtt_history:
		sum += rtt
	return sum / _rtt_history.size()

func get_min_rtt_ms() -> float:
	if _rtt_history.is_empty():
		return 0.0
	var min_val: float = _rtt_history[0]
	for rtt in _rtt_history:
		if rtt < min_val:
			min_val = rtt
	return min_val

func get_max_rtt_ms() -> float:
	if _rtt_history.is_empty():
		return 0.0
	var max_val: float = _rtt_history[0]
	for rtt in _rtt_history:
		if rtt > max_val:
			max_val = rtt
	return max_val

func reset() -> void:
	_rtt_history.clear()
	_ping_sequence = 0
