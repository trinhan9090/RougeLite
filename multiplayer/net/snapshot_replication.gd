class_name SnapshotReplication
extends Node
## Server-to-client state synchronization with delta compression and relevance filtering.
## Sends position, health, animation state for visible entities.

signal snapshot_received(tick: int, entities: Array[Dictionary])

var _last_sent_snapshot_tick: int = 0
var _snapshot_rate_hz: int = 20  # 50ms per snapshot
var _snapshot_interval: float = 1.0 / _snapshot_rate_hz
var _time_since_last_snapshot: float = 0.0

# Interpolation buffer for clients
var _snapshot_buffer: Array[Dictionary] = []
var _max_buffer_size: int = 5

func _process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server():
		return
	_time_since_last_snapshot += delta
	if _time_since_last_snapshot >= _snapshot_interval:
		_time_since_last_snapshot = 0.0
		_send_snapshot()

func _send_snapshot() -> void:
	var tick: int = Time.get_ticks_msec()
	var entities: Array[Dictionary] = _collect_entity_states()

	# Send to all clients
	for peer_id in multiplayer.get_peers():
		rpc_id(peer_id, "_receive_snapshot", tick, entities)

	_last_sent_snapshot_tick = tick

func _collect_entity_states() -> Array[Dictionary]:
	# Collect relevant entity states
	# This will be implemented to query the authoritative world
	var entities: Array[Dictionary] = []

	# TODO: Collect player states
	# TODO: Collect enemy states (nearby only, relevance filtering)
	# TODO: Collect projectile states
	# TODO: Collect orb states

	return entities

@rpc("authority", "unreliable_ordered")
func _receive_snapshot(tick: int, entities: Array[Dictionary]) -> void:
	if multiplayer.is_server():
		return

	var snapshot := {
		"tick": tick,
		"entities": entities,
		"received_at": Time.get_ticks_msec()
	}

	_snapshot_buffer.append(snapshot)
	if _snapshot_buffer.size() > _max_buffer_size:
		_snapshot_buffer.pop_front()

	snapshot_received.emit(tick, entities)

func get_interpolated_state(entity_id: int, current_time: float) -> Dictionary:
	# Find two snapshots to interpolate between
	if _snapshot_buffer.size() < 2:
		return {}

	# Simple interpolation between two most recent snapshots
	var snap_a := _snapshot_buffer[_snapshot_buffer.size() - 2]
	var snap_b := _snapshot_buffer[_snapshot_buffer.size() - 1]

	var t := inverse_lerp(snap_a.received_at, snap_b.received_at, current_time)
	t = clampf(t, 0.0, 1.0)

	# Find entity in both snapshots
	var entity_a: Dictionary = _find_entity_in_snapshot(snap_a, entity_id)
	var entity_b: Dictionary = _find_entity_in_snapshot(snap_b, entity_id)

	if entity_a.is_empty() or entity_b.is_empty():
		return entity_b if not entity_b.is_empty() else entity_a

	# Interpolate position
	if entity_a.has("position") and entity_b.has("position"):
		var pos_a := Vector2(entity_a.position.x, entity_a.position.y)
		var pos_b := Vector2(entity_b.position.x, entity_b.position.y)
		var interpolated_pos := pos_a.lerp(pos_b, t)
		entity_b.position = {"x": interpolated_pos.x, "y": interpolated_pos.y}

	return entity_b

func _find_entity_in_snapshot(snapshot: Dictionary, entity_id: int) -> Dictionary:
	for entity in snapshot.entities:
		if entity.has("id") and entity.id == entity_id:
			return entity
	return {}

func reset() -> void:
	_snapshot_buffer.clear()
	_last_sent_snapshot_tick = 0
	_time_since_last_snapshot = 0.0
