class_name SessionManager
extends Node
## Manages player roster, authorization, and host/join validation.
## Only the host mutates roster state; clients receive updates via RPC.

signal player_joined(player_id: int, peer_id: int)
signal player_left(player_id: int, reason: String)
signal session_full()
signal player_authorized(peer_id: int)

const MAX_PLAYERS: int = 4
var players: Dictionary[int, PlayerSession] = {}  # peer_id → PlayerSession
var _next_player_id: int = 1

class PlayerSession:
	var player_id: int
	var peer_id: int
	var character_id: StringName = &""
	var connected_at: float = 0.0
	var authorized: bool = false
	var last_activity_tick: int = 0

func register_host_player(character_id: StringName = &"default") -> int:
	# Host is always peer ID 1
	var player_session := PlayerSession.new()
	player_session.player_id = _next_player_id
	player_session.peer_id = 1
	player_session.character_id = character_id
	player_session.connected_at = Time.get_ticks_msec() / 1000.0
	player_session.authorized = true
	players[1] = player_session
	var id := _next_player_id
	_next_player_id += 1
	player_joined.emit(id, 1)
	return id

func try_join_peer(peer_id: int, requested_character: StringName) -> Dictionary:
	# Returns {accepted: bool, player_id: int, reason: String}
	if players.size() >= MAX_PLAYERS:
		return {"accepted": false, "player_id": -1, "reason": "Session full (max %d players)" % MAX_PLAYERS}

	if players.has(peer_id):
		return {"accepted": false, "player_id": players[peer_id].player_id, "reason": "Already joined"}

	var player_session := PlayerSession.new()
	player_session.player_id = _next_player_id
	player_session.peer_id = peer_id
	player_session.character_id = requested_character
	player_session.connected_at = Time.get_ticks_msec() / 1000.0
	player_session.authorized = true

	players[peer_id] = player_session
	var assigned_id := _next_player_id
	_next_player_id += 1

	player_joined.emit(assigned_id, peer_id)
	player_authorized.emit(peer_id)
	return {"accepted": true, "player_id": assigned_id, "reason": ""}

func remove_peer(peer_id: int, reason: String = "disconnect") -> void:
	if not players.has(peer_id):
		return
	var player_id: int = players[peer_id].player_id
	players.erase(peer_id)
	player_left.emit(player_id, reason)

func get_player_count() -> int:
	return players.size()

func is_full() -> bool:
	return players.size() >= MAX_PLAYERS

func get_player_id_for_peer(peer_id: int) -> int:
	if not players.has(peer_id):
		return -1
	return players[peer_id].player_id

func get_peer_id_for_player(player_id: int) -> int:
	for peer_id in players:
		if players[peer_id].player_id == player_id:
			return peer_id
	return -1

func get_session_for_player(player_id: int) -> PlayerSession:
	for peer_id in players:
		if players[peer_id].player_id == player_id:
			return players[peer_id]
	return null

func get_all_player_ids() -> Array[int]:
	var ids: Array[int] = []
	for peer_id in players:
		ids.append(players[peer_id].player_id)
	return ids

func reset() -> void:
	players.clear()
	_next_player_id = 1
