extends Node
## Multiplayer combat run coordinator - bridges MP systems with combat.
## Extends CombatRunRoot logic to handle multiple players.

var multiplayer_coordinator: MultiplayerCoordinator
var game_bridge: MultiplayerGameBridge
var is_multiplayer_mode: bool = false
var local_player_id: int = -1
var selected_character: StringName = &"astra"

func _ready() -> void:
	multiplayer_coordinator = get_node("/root/MultiplayerCoordinator")
	game_bridge = MultiplayerGameBridge.new()
	add_child(game_bridge)

func start_host_session(character_id: StringName, port: int = 24567) -> Error:
	selected_character = character_id
	var err := multiplayer_coordinator.start_host_session(port)
	if err != OK:
		push_error("Failed to start host: %s" % error_string(err))
		return err

	is_multiplayer_mode = true
	_setup_host_session()
	return OK

func join_client_session(character_id: StringName, address: String, port: int = 24567) -> Error:
	selected_character = character_id
	var err := multiplayer_coordinator.join_session(address, port)
	if err != OK:
		push_error("Failed to join session: %s" % error_string(err))
		return err

	is_multiplayer_mode = true
	# Wait for connection confirmation
	await multiplayer_coordinator.network_manager.connected_to_server
	_setup_client_session()
	return OK

func _setup_host_session() -> void:
	print("MultiplayerCombatRun: Setting up host session")

	# Register host player
	local_player_id = multiplayer_coordinator.session_manager.register_host_player(selected_character)

	# Initialize map and wait for clients
	multiplayer_coordinator.start_match(&"map.temple")

	# Spawn host player actor
	await multiplayer_coordinator.map_sync.all_clients_ready
	_spawn_local_player()

func _setup_client_session() -> void:
	print("MultiplayerCombatRun: Setting up client session")

	# Send join request to server
	rpc_id(1, "_server_receive_join_request", multiplayer.get_unique_id(), selected_character)

@rpc("any_peer", "reliable")
func _server_receive_join_request(peer_id: int, character_id: StringName) -> void:
	if not multiplayer.is_server():
		return

	print("MultiplayerCombatRun: Received join request from peer %d" % peer_id)

	# Register player
	var result := multiplayer_coordinator.session_manager.try_join_peer(peer_id, character_id)

	if result.accepted:
		# Notify client of success
		rpc_id(peer_id, "_client_receive_join_accepted", result.player_id)

		# Broadcast to all clients
		for other_peer in multiplayer.get_peers():
			if other_peer != peer_id:
				rpc_id(other_peer, "_client_receive_player_joined", result.player_id, character_id)
	else:
		# Notify client of rejection
		rpc_id(peer_id, "_client_receive_join_rejected", result.reason)

@rpc("authority", "reliable")
func _client_receive_join_accepted(player_id: int) -> void:
	print("MultiplayerCombatRun: Join accepted, assigned player_id %d" % player_id)
	local_player_id = player_id
	_spawn_local_player()

@rpc("authority", "reliable")
func _client_receive_join_rejected(reason: String) -> void:
	push_error("MultiplayerCombatRun: Join rejected: %s" % reason)
	# TODO: Show error UI and return to menu

@rpc("authority", "reliable")
func _client_receive_player_joined(player_id: int, character_id: StringName) -> void:
	print("MultiplayerCombatRun: Player %d joined with character %s" % [player_id, character_id])
	# TODO: Spawn remote player actor

func _spawn_local_player() -> void:
	print("MultiplayerCombatRun: Spawning local player %d with character %s" % [local_player_id, selected_character])

	# TODO: Create actual PlayerActor from existing system
	# For now, create placeholder
	var player := Node2D.new()
	player.name = "Player_%d" % local_player_id
	player.position = Vector2(500, 300)  # TODO: Get spawn point
	add_child(player)

	# Register with game bridge
	game_bridge.register_player_actor(local_player_id, selected_character, player)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_mode:
		return

	if local_player_id < 0:
		return

	# Collect local input
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var aim := get_global_mouse_position()

	var actions := {
		"attack": Input.is_action_pressed("attack"),
		"skill_j": Input.is_action_just_pressed("skill_j"),
		"skill_k": Input.is_action_just_pressed("skill_k"),
		"skill_l": Input.is_action_just_pressed("skill_l"),
		"skill_i": Input.is_action_just_pressed("skill_i"),
		"revive": Input.is_action_pressed("revive")  # F key
	}

	# Submit to multiplayer system
	game_bridge.process_local_input(movement, aim, actions)

func end_session() -> void:
	if is_multiplayer_mode:
		multiplayer_coordinator.stop_session()
		is_multiplayer_mode = false
		local_player_id = -1
