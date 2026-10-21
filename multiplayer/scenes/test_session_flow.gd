extends SceneTree
## End-to-end test of the real multiplayer UI flow:
## MultiplayerSessionFlow -> host/join -> lobby -> start -> MultiplayerCombatRun.
##
## Host:   godot --headless --path . --script res://multiplayer/scenes/test_session_flow.gd -- --role=host --port=24690
## Client: godot --headless --path . --script res://multiplayer/scenes/test_session_flow.gd -- --role=client --port=24690

const TIMEOUT_SECONDS := 30.0

var _role: String = "host"
var _port: int = 24567
var _checks: int = 0
var _failures: int = 0

var _flow: Node = null
var _coordinator: Node = null
var _local_player_id: int = -1

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

func _in_game() -> bool:
	return current_scene != null and String(current_scene.name) == "MultiplayerCombatRun"

func _local_actor() -> Node:
	if not _in_game():
		return null
	var combat_root = current_scene.get("combat_root")
	if combat_root == null:
		return null
	return combat_root.get("player")

func _run() -> void:
	print("=== MULTIPLAYER UI FLOW TEST role=%s port=%d ===" % [_role, _port])

	# The real input actions are registered at runtime by the Settings autoload.
	_check(InputMap.has_action("move_left"), "movement input action registered")
	_check(InputMap.has_action("basic_attack"), "basic attack input action registered")
	_check(InputMap.has_action("active_1"), "skill input action registered")

	_coordinator = root.get_node_or_null("MultiplayerCoordinator")
	_check(_coordinator != null, "MultiplayerCoordinator autoload exists")
	if _coordinator == null:
		_finish()
		return
	_coordinator.local_player_registered.connect(func(player_id: int, _character: StringName) -> void:
		_local_player_id = player_id
	)

	change_scene_to_file("res://multiplayer/scenes/multiplayer_session_flow.tscn")
	await process_frame
	await process_frame
	await process_frame
	_flow = current_scene
	_check(_flow != null and String(_flow.name) == "MultiplayerSessionFlow", "session flow scene loaded")

	if _flow == null:
		_finish()
		return

	if _role == "host":
		await _run_host()
	else:
		await _run_client()

	_finish()

func _run_host() -> void:
	_flow.host_port = _port
	_flow._on_host_requested()
	_check(await _wait_until(func() -> bool: return _flow.lobby.visible), "lobby shown after hosting")
	_check(_coordinator.is_host(), "coordinator is host")

	_check(await _wait_until(func() -> bool: return _coordinator.network_manager.get_peer_count() >= 2, 30.0), "client joined the lobby")

	_flow._on_start_pressed()
	_check(await _wait_until(_in_game, 30.0), "host entered combat scene")

	_check(await _wait_until(func() -> bool: return _local_player_id > 0, 30.0), "host local player registered")
	_check(await _wait_until(func() -> bool: return _coordinator.session_manager.get_player_count() == 2, 30.0), "host roster has both players")

	var client_peer: int = -1
	for peer in _coordinator.session_manager.players:
		if int(peer) != 1:
			client_peer = int(peer)
	var client_player_id: int = _coordinator.session_manager.get_player_id_for_peer(client_peer) if client_peer > 0 else -1
	_check(await _wait_until(func() -> bool:
		var state = _coordinator.authoritative_world.get_player_state(client_player_id)
		return state != null and state.last_input_seq > 0
	, 30.0), "host received replicated client input")

	var player_node := _local_actor()
	_check(player_node != null, "host local actor spawned in world")

	_check(await _wait_until(func() -> bool:
		var ghost_owner = current_scene.get("_ghosts") if _in_game() else null
		return ghost_owner is Dictionary and ghost_owner.has(client_player_id)
	, 15.0), "host sees client ghost")

	var ghost = _ghost_for(client_player_id)
	var ghost_start: Vector2 = ghost.global_position if ghost != null else Vector2.ZERO
	_check(await _wait_until(func() -> bool:
		var g = _ghost_for(client_player_id)
		return g != null and g.global_position.distance_to(ghost_start) > 5.0
	, 20.0), "host sees client ghost move")

	_check(await _wait_until(func() -> bool: return root.multiplayer.get_peers().is_empty(), 15.0), "client left cleanly")
	_coordinator.stop_session()

func _ghost_for(player_id: int) -> Node2D:
	if not _in_game():
		return null
	var ghosts = current_scene.get("_ghosts")
	if ghosts is not Dictionary:
		return null
	return ghosts.get(player_id) as Node2D

func _run_client() -> void:
	_flow._on_join_requested("127.0.0.1", _port)
	_check(await _wait_until(func() -> bool: return _flow.lobby.visible), "lobby shown after connecting")
	_check(_coordinator.is_client(), "coordinator is client")

	_check(await _wait_until(_in_game), "client entered combat scene on match start")
	_check(await _wait_until(func() -> bool: return _local_player_id > 0), "client local player registered by host")

	var player_node := _local_actor()
	_check(player_node != null, "client local actor spawned in world")
	_check(await _wait_until(func() -> bool:
		var ghosts = current_scene.get("_ghosts") if _in_game() else null
		return ghosts is Dictionary and ghosts.has(1)
	, 15.0), "client sees host ghost")
	_check(await _wait_until(func() -> bool: return _coordinator.input_replication._local_sequence > 0), "client is sending input frames")

	# Move for a moment so the host can confirm ghost position replication.
	await create_timer(1.0).timeout
	Input.action_press("move_right")
	await create_timer(3.0).timeout
	Input.action_release("move_right")
	await create_timer(1.0).timeout
	_coordinator.stop_session()

func _finish() -> void:
	print("RESULT session_flow_%s: checks=%d failures=%d" % [_role, _checks, _failures])
	quit(0 if _failures == 0 else 1)
