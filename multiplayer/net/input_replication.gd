class_name InputReplication
extends Node
## Client input collection, sequencing, and replication to server.
## Each client sends inputs with sequence numbers; server processes in order.

signal input_received(player_id: int, input_frame: Dictionary)

var _local_sequence: int = 0
var _pending_inputs: Array[Dictionary] = []
var _input_buffer_size: int = 10
var _last_acked_sequence: int = -1

func collect_local_input(movement: Vector2, aim: Vector2, actions: Dictionary) -> Dictionary:
	_local_sequence += 1
	var input_frame := {
		"seq": _local_sequence,
		"tick": Time.get_ticks_msec(),
		"movement": movement,
		"aim": aim,
		"actions": actions  # {action_name: bool}
	}
	_pending_inputs.append(input_frame)
	if _pending_inputs.size() > _input_buffer_size:
		_pending_inputs.pop_front()
	return input_frame

func send_input_to_server(input_frame: Dictionary) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	rpc_id(1, "_receive_client_input", input_frame)

@rpc("any_peer", "unreliable_ordered")
func _receive_client_input(input_frame: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	# Validate input structure
	if not input_frame.has("seq") or not input_frame.has("movement") or not input_frame.has("actions"):
		push_error("InputReplication: Invalid input frame from peer %d" % sender_id)
		return
	# Emit for authoritative world to process
	input_received.emit(sender_id, input_frame)

func acknowledge_input(seq: int) -> void:
	_last_acked_sequence = seq
	# Clean up confirmed inputs
	while not _pending_inputs.is_empty() and _pending_inputs[0].seq <= seq:
		_pending_inputs.pop_front()

func get_pending_input_count() -> int:
	return _pending_inputs.size()

func reset() -> void:
	_local_sequence = 0
	_pending_inputs.clear()
	_last_acked_sequence = -1
