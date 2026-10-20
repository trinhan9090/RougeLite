extends Node
## Central coordinator that wires all multiplayer authority modules together.
## Single autoload that manages MP lifecycle and delegates to specialized systems.

signal session_started()
signal session_ended()
signal player_joined_session(player_id: int, character_id: StringName)
signal player_left_session(player_id: int)
signal client_ready_to_play(player_id: int)
signal map_ready_for_clients()

var network_manager: NetworkManager
var session_manager: SessionManager
var input_replication: InputReplication
var snapshot_replication: SnapshotReplication
var prediction_reconciliation: PredictionReconciliation
var authoritative_world: AuthoritativeWorld
var exp_orb_authority: ExpOrbAuthority
var augment_offer_authority: AugmentOfferAuthority
var time_encounter_director: TimeEncounterDirector
var match_clock_authority: MatchClockAuthority
var revive_authority: ReviveAuthority
var map_sync: MapSync
var net_diagnostics: NetworkDiagnostics

var _is_multiplayer_active: bool = false

func _ready() -> void:
	_initialize_modules()
	_connect_signals()

func _initialize_modules() -> void:
	# Create all authority modules
	network_manager = NetworkManager.new()
	session_manager = SessionManager.new()
	input_replication = InputReplication.new()
	snapshot_replication = SnapshotReplication.new()
	prediction_reconciliation = PredictionReconciliation.new()
	authoritative_world = AuthoritativeWorld.new()
	exp_orb_authority = ExpOrbAuthority.new()
	augment_offer_authority = AugmentOfferAuthority.new()
	time_encounter_director = TimeEncounterDirector.new()
	match_clock_authority = MatchClockAuthority.new()
	revive_authority = ReviveAuthority.new()
	map_sync = MapSync.new()
	net_diagnostics = NetworkDiagnostics.new()

	# Add as children
	add_child(network_manager)
	add_child(session_manager)
	add_child(input_replication)
	add_child(snapshot_replication)
	add_child(prediction_reconciliation)
	add_child(authoritative_world)
	add_child(exp_orb_authority)
	add_child(augment_offer_authority)
	add_child(time_encounter_director)
	add_child(match_clock_authority)
	add_child(revive_authority)
	add_child(map_sync)
	add_child(net_diagnostics)

	print("MultiplayerCoordinator: All modules initialized")

func _connect_signals() -> void:
	# Network lifecycle
	network_manager.peer_connected.connect(_on_peer_connected)
	network_manager.peer_disconnected.connect(_on_peer_disconnected)
	network_manager.server_started.connect(_on_server_started)

	# Session management
	session_manager.player_joined.connect(_on_player_joined)
	session_manager.player_left.connect(_on_player_left)

	# Input processing
	input_replication.input_received.connect(_on_input_received)

	# EXP system
	exp_orb_authority.orb_claimed.connect(_on_orb_claimed)

	# Match clock
	match_clock_authority.match_ended.connect(_on_match_ended)

func start_host_session(port: int = NetworkManager.DEFAULT_PORT) -> Error:
	var err := network_manager.start_host(port)
	if err != OK:
		return err

	_is_multiplayer_active = true
	return OK

func join_session(address: String, port: int = NetworkManager.DEFAULT_PORT) -> Error:
	var err := network_manager.join_host(address, port)
	if err != OK:
		return err

	_is_multiplayer_active = true
	return OK

func stop_session() -> void:
	network_manager.stop()
	_reset_all_modules()
	_is_multiplayer_active = false
	session_ended.emit()

func start_match(map_id: StringName) -> void:
	if not multiplayer.is_server():
		return

	# Initialize map
	var seed := randi()
	map_sync.initialize_map_on_host(map_id, seed)

	# Wait for all clients ready (handled by map_sync signal)
	await map_sync.all_clients_ready

	# Start match clock
	match_clock_authority.start_match()

	# Broadcast to all clients that map is ready
	rpc("_client_receive_map_ready")

	# Host can start immediately
	session_started.emit()

@rpc("authority", "reliable")
func _client_receive_map_ready() -> void:
	if multiplayer.is_server():
		return
	print("MultiplayerCoordinator: Client received map_ready signal")
	session_started.emit()

func register_local_player(character_id: StringName, actor_node: Node) -> int:
	if multiplayer.is_server():
		var player_id := session_manager.register_host_player(character_id)
		authoritative_world.register_player(player_id, 1, character_id, actor_node)
		return player_id
	else:
		# Client sends join request
		# TODO: Implement handshake protocol
		return -1

func submit_local_input(movement: Vector2, aim: Vector2, actions: Dictionary) -> void:
	if not _is_multiplayer_active:
		return

	var input_frame := input_replication.collect_local_input(movement, aim, actions)
	input_replication.send_input_to_server(input_frame)

	# Predict locally if this is our player
	if not multiplayer.is_server():
		var predicted_pos := prediction_reconciliation.predict_movement(input_frame, 0.016, 200.0)
		# TODO: Apply to local player visual

func _on_peer_connected(peer_id: int) -> void:
	print("MultiplayerCoordinator: Peer %d connected" % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("MultiplayerCoordinator: Peer %d disconnected" % peer_id)
	session_manager.remove_peer(peer_id, "disconnect")
	# TODO: Handle player leaving during match

func _on_server_started() -> void:
	print("MultiplayerCoordinator: Server started")

func _on_player_joined(player_id: int, peer_id: int) -> void:
	print("MultiplayerCoordinator: Player %d joined (peer %d)" % [player_id, peer_id])
	player_joined_session.emit(player_id, &"default")

func _on_player_left(player_id: int, reason: String) -> void:
	print("MultiplayerCoordinator: Player %d left (%s)" % [player_id, reason])
	authoritative_world.unregister_player(player_id)
	player_left_session.emit(player_id)

func _on_input_received(peer_id: int, input_frame: Dictionary) -> void:
	if not multiplayer.is_server():
		return

	var player_id := session_manager.get_player_id_for_peer(peer_id)
	if player_id < 0:
		return

	authoritative_world.apply_player_input(player_id, input_frame)

func _on_orb_claimed(orb_id: int, player_id: int, exp_amount: int) -> void:
	# Grant EXP to player
	# TODO: Integrate with existing progression system
	print("MultiplayerCoordinator: Player %d claimed orb %d for %d EXP" % [player_id, orb_id, exp_amount])

func _on_match_ended(final_time: float) -> void:
	print("MultiplayerCoordinator: Match ended at %.2fs" % final_time)
	# TODO: Show end screen with scores

func _reset_all_modules() -> void:
	session_manager.reset()
	input_replication.reset()
	snapshot_replication.reset()
	prediction_reconciliation.reset()
	authoritative_world.reset()
	exp_orb_authority.reset()
	augment_offer_authority.reset()
	time_encounter_director.reset()
	match_clock_authority.reset()
	revive_authority.reset()
	map_sync.reset()
	net_diagnostics.reset()

func is_multiplayer_active() -> bool:
	return _is_multiplayer_active

func is_host() -> bool:
	return network_manager.is_host()

func is_client() -> bool:
	return network_manager.is_client()
