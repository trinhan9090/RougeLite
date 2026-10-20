extends Node
## Quick test script to verify host creation works.

func _ready() -> void:
	print("=== MULTIPLAYER HOST TEST ===")

	# Wait for autoload
	await get_tree().process_frame

	if not has_node("/root/MultiplayerCoordinator"):
		print("ERROR: MultiplayerCoordinator not found!")
		get_tree().quit()
		return

	var coordinator = get_node("/root/MultiplayerCoordinator")
	print("Coordinator found: ", coordinator)
	print("NetworkManager: ", coordinator.network_manager)

	# Try to start host
	print("Attempting to start host on port 24567...")
	var err = coordinator.start_host_session(24567)
	print("Result: ", err, " (OK = ", OK, ")")

	if err == OK:
		print("✓ Host started successfully!")
		print("Waiting 2 seconds...")
		await get_tree().create_timer(2.0).timeout
		print("Stopping host...")
		coordinator.stop_session()
		print("✓ Test complete")
	else:
		print("✗ Failed to start host: ", error_string(err))

	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
