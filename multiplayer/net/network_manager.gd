class_name NetworkManager
extends Node
## ENet peer lifecycle manager. Autoloaded singleton for multiplayer session control.

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal connection_failed(reason: String)
signal server_started()
signal server_stopped()

const DEFAULT_PORT: int = 24567
const MAX_CLIENTS: int = 3  # Host + 3 clients = 4 total players
const PROTOCOL_VERSION: String = "endless_survival_mp_v1.2"

var _peer: ENetMultiplayerPeer = null
var _is_host: bool = false
var _connection_timeout: float = 10.0
var _connection_attempt_time: float = 0.0

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func is_host() -> bool:
	return _is_host and multiplayer.is_server()

func is_client() -> bool:
	return _has_network_peer() and not multiplayer.is_server()

func is_active() -> bool:
	return _has_network_peer()

## Godot starts with an OfflineMultiplayerPeer assigned, so has_multiplayer_peer()
## is true even when no real network session exists. Only a non-offline peer counts.
func _has_network_peer() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return false
	return not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer)

func start_host(port: int = DEFAULT_PORT) -> Error:
	if _has_network_peer():
		push_error("NetworkManager: Cannot start host, peer already active")
		return ERR_ALREADY_IN_USE

	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("NetworkManager: Failed to create server on port %d: %s" % [port, error_string(err)])
		_peer = null
		return err

	multiplayer.multiplayer_peer = _peer
	_is_host = true
	print("NetworkManager: Host started on port %d, max %d clients" % [port, MAX_CLIENTS])
	server_started.emit()
	return OK

func join_host(address: String, port: int = DEFAULT_PORT) -> Error:
	if _has_network_peer():
		push_error("NetworkManager: Cannot join, peer already active")
		return ERR_ALREADY_IN_USE

	if address.strip_edges().is_empty():
		push_error("NetworkManager: Empty address")
		return ERR_INVALID_PARAMETER

	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(address, port)
	if err != OK:
		push_error("NetworkManager: Failed to create client to %s:%d: %s" % [address, port, error_string(err)])
		_peer = null
		return err

	multiplayer.multiplayer_peer = _peer
	_is_host = false
	_connection_attempt_time = Time.get_ticks_msec() / 1000.0
	print("NetworkManager: Connecting to %s:%d..." % [address, port])
	return OK

func stop() -> void:
	if _peer != null:
		_peer.close()
		_peer = null
	# Restore the offline peer instead of null so get_unique_id()/is_server()
	# keep working after a session ends (Idle modules poll them every frame).
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_is_host = false
	_connection_attempt_time = 0.0
	print("NetworkManager: Session stopped")
	server_stopped.emit()

func get_peer_count() -> int:
	if not _has_network_peer():
		return 0
	# Host counts as 1, plus connected clients
	return 1 + multiplayer.get_peers().size()

func get_unique_id() -> int:
	return multiplayer.get_unique_id()

func _physics_process(_delta: float) -> void:
	# Connection timeout check for clients
	if is_client() and _connection_attempt_time > 0.0:
		var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _connection_attempt_time
		if elapsed > _connection_timeout:
			push_error("NetworkManager: Connection timeout after %.1fs" % elapsed)
			connection_failed.emit("Connection timeout")
			stop()

func _on_peer_connected(peer_id: int) -> void:
	print("NetworkManager: Peer %d connected (total: %d)" % [peer_id, get_peer_count()])
	peer_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("NetworkManager: Peer %d disconnected (remaining: %d)" % [peer_id, get_peer_count()])
	peer_disconnected.emit(peer_id)

func _on_connected_to_server() -> void:
	_connection_attempt_time = 0.0
	print("NetworkManager: Successfully connected to server as peer %d" % get_unique_id())

func _on_connection_failed() -> void:
	push_error("NetworkManager: Connection failed")
	connection_failed.emit("Connection refused or unreachable")
	stop()

func _on_server_disconnected() -> void:
	push_error("NetworkManager: Server disconnected")
	connection_failed.emit("Server disconnected")
	stop()
