class_name PredictionReconciliation
extends Node
## Client-side prediction and server reconciliation for owned player only.
## Non-owned entities use snapshot interpolation.

signal reconciliation_applied(corrected_position: Vector2, error_magnitude: float)

var _is_predicting: bool = false
var _predicted_position: Vector2 = Vector2.ZERO
var _predicted_velocity: Vector2 = Vector2.ZERO
var _prediction_history: Array[Dictionary] = []
var _max_history_size: int = 30
var _reconciliation_threshold: float = 5.0  # pixels

func enable_prediction(enable: bool) -> void:
	_is_predicting = enable

func predict_movement(input: Dictionary, delta: float, move_speed: float) -> Vector2:
	if not _is_predicting:
		return Vector2.ZERO

	var movement := input.get("movement", Vector2.ZERO) as Vector2
	if movement.length() > 0.0:
		movement = movement.normalized()

	var predicted_velocity := movement * move_speed
	var predicted_position := _predicted_position + predicted_velocity * delta

	# Store prediction for reconciliation
	_prediction_history.append({
		"seq": input.get("seq", 0),
		"position": predicted_position,
		"velocity": predicted_velocity,
		"tick": Time.get_ticks_msec()
	})

	if _prediction_history.size() > _max_history_size:
		_prediction_history.pop_front()

	_predicted_position = predicted_position
	_predicted_velocity = predicted_velocity

	return predicted_position

func reconcile_with_server(server_position: Vector2, server_seq: int) -> Vector2:
	if not _is_predicting:
		return server_position

	# Find prediction matching this server update
	var prediction_index := -1
	for i in range(_prediction_history.size()):
		if _prediction_history[i].seq == server_seq:
			prediction_index = i
			break

	if prediction_index == -1:
		# No matching prediction, accept server position
		_predicted_position = server_position
		return server_position

	# Calculate prediction error
	var predicted_pos := _prediction_history[prediction_index].position as Vector2
	var error := server_position.distance_to(predicted_pos)

	if error > _reconciliation_threshold:
		# Significant error, snap to server position and replay inputs
		_predicted_position = server_position

		# Replay unacknowledged inputs
		for i in range(prediction_index + 1, _prediction_history.size()):
			var hist := _prediction_history[i]
			# Simple replay (would need actual physics in real impl)
			_predicted_position += hist.velocity * 0.016  # Assume 60fps

		reconciliation_applied.emit(server_position, error)
	else:
		# Small error, blend smoothly
		_predicted_position = _predicted_position.lerp(server_position, 0.1)

	# Clean old predictions
	if prediction_index >= 0:
		_prediction_history = _prediction_history.slice(prediction_index + 1)

	return _predicted_position

func set_position(pos: Vector2) -> void:
	_predicted_position = pos

func get_predicted_position() -> Vector2:
	return _predicted_position

func reset() -> void:
	_is_predicting = false
	_predicted_position = Vector2.ZERO
	_predicted_velocity = Vector2.ZERO
	_prediction_history.clear()
