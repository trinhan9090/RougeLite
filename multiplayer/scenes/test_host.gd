extends SceneTree
## Headless host-creation smoke test.
## Run with: godot --headless --path . --script res://multiplayer/scenes/test_host.gd

var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", label)
	else:
		_failures += 1
		printerr("FAIL ", label)

func _run() -> void:
	print("=== MULTIPLAYER HOST TEST ===")

	var coordinator := root.get_node_or_null("MultiplayerCoordinator")
	_check(coordinator != null, "MultiplayerCoordinator autoload exists")
	if coordinator == null:
		_finish()
		return

	_check(coordinator.network_manager != null, "NetworkManager module created")
	_check(coordinator.map_sync != null, "MapSync module created")
	_check(coordinator.session_manager != null, "SessionManager module created")

	var port := 24567
	var err: int = coordinator.start_host_session(port)
	_check(err == OK, "start_host_session returns OK")
	_check(coordinator.is_host(), "coordinator reports host role")
	_check(coordinator.network_manager.get_peer_count() == 1, "solo host counts as one peer")

	await process_frame
	await process_frame
	_check(coordinator.network_manager.is_active(), "multiplayer peer remains active")

	coordinator.stop_session()
	_check(not coordinator.network_manager.is_active(), "stop_session clears multiplayer peer")
	_check(not coordinator.is_multiplayer_active(), "stop_session clears active flag")

	_finish()

func _finish() -> void:
	print("RESULT multiplayer_host: checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
