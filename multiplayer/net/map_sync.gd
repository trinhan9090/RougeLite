class_name MapSync
extends Node
## ONE-TIME map initialization handshake at run start.
## Host selects map seed/layout; clients validate matching geometry.

signal map_initialized(map_id: StringName, map_seed: int, checksum: String)
signal map_validation_failed(reason: String)
signal all_clients_ready()

var _map_id: StringName = &""
var _map_seed: int = 0
var _generator_version: String = "v1.0"
var _layout_checksum: String = ""
var _client_ready_states: Dictionary = {}  # peer_id → bool
var _is_initialized: bool = false

func initialize_map_on_host(map_id: StringName, seed: int) -> void:
	if not multiplayer.is_server():
		push_error("MapSync: Only server can initialize map")
		return

	if _is_initialized:
		push_error("MapSync: Map already initialized this run")
		return

	_map_id = map_id
	_map_seed = seed
	_layout_checksum = _generate_checksum(map_id, seed)
	_is_initialized = true

	map_initialized.emit(map_id, seed, _layout_checksum)
	print("MapSync: Host initialized map '%s' with seed %d (checksum: %s)" % [map_id, seed, _layout_checksum])

	# Broadcast to all clients
	for peer_id in multiplayer.get_peers():
		rpc_id(peer_id, "_client_receive_map_init", map_id, seed, _generator_version, _layout_checksum)
		_client_ready_states[peer_id] = false

@rpc("authority", "reliable")
func _client_receive_map_init(map_id: StringName, seed: int, version: String, checksum: String) -> void:
	if multiplayer.is_server():
		return

	_map_id = map_id
	_map_seed = seed
	_generator_version = version
	_layout_checksum = checksum

	# Generate local map and validate checksum
	var local_checksum := _generate_checksum(map_id, seed)
	if local_checksum != checksum:
		map_validation_failed.emit("Checksum mismatch: expected %s, got %s" % [checksum, local_checksum])
		push_error("MapSync: Map validation failed")
		# TODO: Request authoritative layout from server
		return

	# Report ready to server
	rpc_id(1, "_server_receive_client_ready", multiplayer.get_unique_id())

	map_initialized.emit(map_id, seed, checksum)
	print("MapSync: Client validated map '%s' seed %d" % [map_id, seed])

@rpc("any_peer", "reliable")
func _server_receive_client_ready(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	_client_ready_states[peer_id] = true
	print("MapSync: Client %d ready" % peer_id)

	# Check if all clients ready
	var all_ready := true
	for pid in _client_ready_states:
		if not _client_ready_states[pid]:
			all_ready = false
			break

	if all_ready:
		all_clients_ready.emit()
		print("MapSync: All clients ready, match can start")

func _generate_checksum(map_id: StringName, seed: int) -> String:
	# Simple checksum based on map generation
	# TODO: Integrate with actual MapGenerator
	var data := "%s_%d_%s" % [map_id, seed, _generator_version]
	return data.md5_text()

func get_map_id() -> StringName:
	return _map_id

func get_map_seed() -> int:
	return _map_seed

func is_initialized() -> bool:
	return _is_initialized

func reset() -> void:
	_map_id = &""
	_map_seed = 0
	_layout_checksum = ""
	_client_ready_states.clear()
	_is_initialized = false
