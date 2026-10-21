extends SceneTree
## Single-process headless verification for the playable multiplayer combat scene.
##
## Checks that the scene boots CombatRunRoot, the local actor exists, input moves
## the player, and Escape opens the pause/settings modal.
##
## Run: godot --headless --path . --script res://multiplayer/scenes/test_combat_scene.gd

var _coordinator: Node
var _scene: Node

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_coordinator = root.get_node_or_null("/root/MultiplayerCoordinator")
	if _coordinator == null:
		print("FAIL no coordinator")
		quit(1)
		return

	var host_err: Error = _coordinator.start_host_session(24599)
	print("host start err=", host_err)
	if host_err != OK:
		print("FAIL host start")
		quit(1)
		return

	await process_frame
	_coordinator.start_match(&"map.temple")
	await _coordinator.session_started
	print("PASS session started")

	var err: Error = change_scene_to_file("res://multiplayer/scenes/multiplayer_combat_run.tscn")
	print("change scene err=", err)
	await process_frame
	await process_frame
	await process_frame
	_scene = current_scene
	if _scene == null:
		print("FAIL no current scene")
		quit(1)
		return

	var combat_root = _scene.get("combat_root")
	print("combat_root=", combat_root)
	if combat_root == null:
		print("FAIL no combat_root")
		quit(1)
		return
	_check(combat_root.player != null, "player exists")
	_check(combat_root.presentation != null, "presentation exists")
	_check(combat_root.state != null and combat_root.state.run_phase == &"RUNNING", "run phase RUNNING")
	_check(InputMap.has_action("pause"), "pause action registered")
	_check(_scene.get("local_player_id") == 1, "local player registered as 1")

	# Movement check.
	var before: Vector2 = combat_root.player.global_position
	Input.action_press("move_right")
	for i in range(20):
		await physics_frame
	Input.action_release("move_right")
	var after: Vector2 = combat_root.player.global_position
	print("moved dx=", after.x - before.x)
	_check(after.x > before.x + 1.0, "player moves right on move_right")

	# Escape / pause check.
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	Input.parse_input_event(esc)
	for i in range(3):
		await process_frame
	print("tree paused=", paused)
	_check(paused, "Escape pauses the game")
	_check(combat_root.state.run_phase == &"PAUSED", "run phase PAUSED")

	_coordinator.stop_session()
	print("RESULT test_combat_scene: failures=%d" % _failures)
	quit(0 if _failures == 0 else 1)

var _failures: int = 0

func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS ", label)
	else:
		_failures += 1
		print("FAIL ", label)
