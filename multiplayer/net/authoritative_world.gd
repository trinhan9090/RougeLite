class_name AuthoritativeWorld
extends Node
## Server-side gameplay simulation bridge. Integrates multiplayer with existing combat system.
## Only the host runs authoritative logic; clients receive state via snapshots.

signal player_moved(player_id: int, position: Vector2)
signal player_damaged(player_id: int, amount: int, current_hp: int)
signal player_died(player_id: int)
signal enemy_spawned(enemy_id: int, type: StringName, position: Vector2)
signal enemy_damaged(enemy_id: int, amount: int, current_hp: int)
signal enemy_died(enemy_id: int, killer_player_id: int)

var _player_states: Dictionary = {}  # player_id → PlayerRuntimeState
var _enemy_instances: Dictionary = {}  # enemy_id → Node
var _projectile_instances: Dictionary = {}  # projectile_id → Node
var _next_entity_id: int = 1000

class PlayerRuntimeState:
	var player_id: int
	var peer_id: int
	var character_id: StringName
	var actor_node: Node = null
	var position: Vector2 = Vector2.ZERO
	var velocity: Vector2 = Vector2.ZERO
	var current_hp: int = 100
	var max_hp: int = 100
	var is_alive: bool = true
	var is_downed: bool = false
	var level: int = 1
	var current_exp: int = 0
	var last_input_seq: int = -1

func register_player(player_id: int, peer_id: int, character_id: StringName, actor_node: Node) -> void:
	var state := PlayerRuntimeState.new()
	state.player_id = player_id
	state.peer_id = peer_id
	state.character_id = character_id
	state.actor_node = actor_node
	state.position = actor_node.global_position if actor_node else Vector2.ZERO
	_player_states[player_id] = state
	print("AuthoritativeWorld: Registered player %d with character %s" % [player_id, character_id])

func unregister_player(player_id: int) -> void:
	_player_states.erase(player_id)
	print("AuthoritativeWorld: Unregistered player %d" % player_id)

func apply_player_input(player_id: int, input_frame: Dictionary) -> void:
	if not multiplayer.is_server():
		return

	var state := _player_states.get(player_id) as PlayerRuntimeState
	if state == null or not state.is_alive:
		return

	# Prevent duplicate processing
	var seq := input_frame.get("seq", 0)
	if seq <= state.last_input_seq:
		return
	state.last_input_seq = seq

	# Apply movement
	var movement := input_frame.get("movement", Vector2.ZERO) as Vector2
	if movement.length() > 0.0:
		movement = movement.normalized()

	# Will integrate with existing PlayerActor movement
	if state.actor_node:
		# Temporary direct application; real impl uses PlayerActor physics
		var move_speed: float = 200.0  # TODO: Get from character data
		state.velocity = movement * move_speed

	# Apply actions (skills, attacks)
	var actions := input_frame.get("actions", {})
	for action_name in actions:
		if actions[action_name]:
			_handle_player_action(player_id, action_name, input_frame.get("aim", Vector2.ZERO))

func _handle_player_action(player_id: int, action_name: String, aim: Vector2) -> void:
	# Delegate to skill controller
	# TODO: Integrate with existing SkillController
	pass

func apply_damage_to_player(player_id: int, amount: int, source_id: int) -> void:
	if not multiplayer.is_server():
		return

	var state := _player_states.get(player_id) as PlayerRuntimeState
	if state == null or not state.is_alive:
		return

	state.current_hp = max(0, state.current_hp - amount)
	player_damaged.emit(player_id, amount, state.current_hp)

	if state.current_hp <= 0 and state.is_alive:
		state.is_alive = false
		state.is_downed = true
		player_died.emit(player_id)

func apply_damage_to_enemy(enemy_id: int, amount: int, attacker_player_id: int) -> void:
	if not multiplayer.is_server():
		return

	# TODO: Integrate with existing enemy system
	# For now, emit event for tracking
	enemy_damaged.emit(enemy_id, amount, 0)

func spawn_enemy(type: StringName, position: Vector2) -> int:
	if not multiplayer.is_server():
		return -1

	var enemy_id := _next_entity_id
	_next_entity_id += 1

	# TODO: Create actual enemy node from existing system
	enemy_spawned.emit(enemy_id, type, position)

	return enemy_id

func get_player_position(player_id: int) -> Vector2:
	var state := _player_states.get(player_id) as PlayerRuntimeState
	return state.position if state else Vector2.ZERO

func get_player_state(player_id: int) -> PlayerRuntimeState:
	return _player_states.get(player_id)

func get_all_alive_players() -> Array[int]:
	var alive: Array[int] = []
	for player_id in _player_states:
		var state := _player_states[player_id] as PlayerRuntimeState
		if state.is_alive:
			alive.append(player_id)
	return alive

func is_player_alive(player_id: int) -> bool:
	var state := _player_states.get(player_id) as PlayerRuntimeState
	return state != null and state.is_alive

func reset() -> void:
	_player_states.clear()
	_enemy_instances.clear()
	_projectile_instances.clear()
	_next_entity_id = 1000
