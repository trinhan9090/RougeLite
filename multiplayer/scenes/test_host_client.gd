extends SceneTree
## Two-process multiplayer integration test.
##
## Host:  godot --headless --path . --script res://multiplayer/scenes/test_host_client.gd -- --role=host --port=24680
## Client: godot --headless --path . --script res://multiplayer/scenes/test_host_client.gd -- --role=client --port=24680
##
## Verifies: ENet connect, map init/checksum handshake, session_started on both
## sides, and client input reaching the host's authoritative world.

const TIMEOUT_SECONDS := 25.0

var _role: String = "host"
var _port: int = 24680
var _checks: int = 0
var _failures: int = 0

var _host_session_started: bool = false
var _client_session_started: bool = false
var _peer_seen: bool = false
var _input_seen: bool = false
var _last_input: Dictionary = {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):
			_role = arg.trim_prefix("--role=")
		elif arg.begins_with("--port="):
			_port = arg.trim_prefix("--port=").to_int()
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", label)
	else:
		_failures += 1
		printerr("FAIL ", label)

func _wait_until(condition: Callable, timeout: float = TIMEOUT_SECONDS) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < int(timeout * 1000.0):
		if condition.call():
			return true
		await process_frame
	return condition.call()

func _run() -> void:
	print("=== MULTIPLAYER HOST/CLIENT TEST role=%s port=%d ===" % [_role, _port])
	var coordinator := root.get_node_or_null("MultiplayerCoordinator")
	_check(coordinator != null, "MultiplayerCoordinator autoload exists")
	if coordinator == null:
		_finish()
		return

	coordinator.session_started.connect(func() -> void:
		if _role == "host":
			_host_session_started = true
		else:
			_client_session_started = true
	)
	coordinator.network_manager.peer_connected.connect(func(_peer_id: int) -> void:
		_peer_seen = true
	)
	coordinator.input_replication.input_received.connect(func(peer_id: int, frame: Dictionary) -> void:
		_input_seen = true
		_last_input = frame
		print("Host observed input from peer %d seq=%d" % [peer_id, int(frame.get("seq", -1))])
	)

	if _role == "host":
		await _run_host(coordinator)
	else:
		await _run_client(coordinator)

	_finish()

func _run_host(coordinator: Node) -> void:
	var err: int = coordinator.start_host_session(_port)
	_check(err == OK, "host started on port %d" % _port)
	if err != OK:
		return
	_check(coordinator.is_host(), "coordinator reports host")

	# Register the host player (peer 1) like the combat run does.
	var host_actor := Node2D.new()
	root.add_child(host_actor)
	var host_player_id: int = coordinator.session_manager.register_host_player(&"astra")
	coordinator.authoritative_world.register_player(host_player_id, 1, &"astra", host_actor)
	_check(host_player_id > 0, "host player registered")

	_check(await _wait_until(func() -> bool: return _peer_seen or coordinator.network_manager.get_peer_count() >= 2), "client peer connected")
	var peers: Array = root.multiplayer.get_peers()
	_check(peers.size() == 1, "exactly one client peer")
	if peers.is_empty():
		return
	var client_peer: int = int(peers[0])

	var join: Dictionary = coordinator.session_manager.try_join_peer(client_peer, &"vex")
	_check(bool(join.get("accepted", false)), "client accepted into session roster")
	var client_player_id: int = int(join.get("player_id", -1))
	# Register the remote actor exactly as the host should when a client joins.
	var client_actor := Node2D.new()
	root.add_child(client_actor)
	coordinator.authoritative_world.register_player(client_player_id, client_peer, &"vex", client_actor)

	# Start the match; this performs the map init handshake and awaits client ready.
	coordinator.start_match(&"map.temple")
	_check(await _wait_until(func() -> bool: return _host_session_started), "host emitted session_started")
	_check(coordinator.map_sync.is_initialized(), "host map initialized")
	_check(coordinator.map_sync.get_map_id() == &"map.temple", "host map id matches")
	_check(coordinator.match_clock_authority.is_running(), "host match clock running")

	_check(await _wait_until(func() -> bool: return _input_seen), "host received client input")
	if _input_seen:
		_check(int(_last_input.get("seq", 0)) > 0, "client input has sequence number")
		_check((_last_input.get("movement", Vector2.ZERO) as Vector2).length() > 0.5, "client movement replicated")
		var state = coordinator.authoritative_world.get_player_state(client_player_id)
		_check(state != null and state.last_input_seq > 0, "host applied input to authoritative world")

	# Let the client finish and disconnect first so neither side logs a false error.
	_check(await _wait_until(func() -> bool: return root.multiplayer.get_peers().is_empty(), 5.0), "client disconnected")
	coordinator.stop_session()
	_check(not coordinator.network_manager.is_active(), "host session stopped cleanly")

func _run_client(coordinator: Node) -> void:
	var err: int = coordinator.join_session("127.0.0.1", _port)
	_check(err == OK, "client join call returned OK")
	if err != OK:
		return

	_check(await _wait_until(func() -> bool: return coordinator.network_manager.is_client()), "client peer became active")
	_check(await _wait_until(func() -> bool: return _peer_seen), "client connected to server")

	_check(await _wait_until(func() -> bool: return _client_session_started), "client emitted session_started")
	_check(coordinator.map_sync.is_initialized(), "client map initialized")
	_check(coordinator.map_sync.get_map_id() == &"map.temple", "client map id matches host")
	_check(coordinator.match_clock_authority.is_running(), "client match clock running")

	# Send a few input frames to the host.
	for index in range(10):
		coordinator.submit_local_input(Vector2(1.0, 0.0), Vector2.RIGHT, {"attack": false})
		await process_frame
	_check(true, "client submitted input frames")

	# Give the host a moment to observe the last frame before disconnecting.
	await create_timer(0.5).timeout
	coordinator.stop_session()
	_check(not coordinator.network_manager.is_active(), "client session stopped cleanly")

func _finish() -> void:
	print("RESULT multiplayer_%s: checks=%d failures=%d" % [_role, _checks, _failures])
	quit(0 if _failures == 0 else 1)
