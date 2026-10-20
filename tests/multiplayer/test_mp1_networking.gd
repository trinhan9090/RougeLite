extends SceneTree
## MP1 Networking Skeleton Tests: T01-T03
## T01: Host + client localhost connection, unique IDs
## T02: 4 total players join (exact max accepted)
## T03: 5th participant rejected safely

var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== MP1 Networking Skeleton Tests (T01-T03) ===")

	# T01: Basic connection logic validation
	await _test_t01_basic_connection()

	# T02: Max players validation
	await _test_t02_max_players()

	# T03: Fifth player rejection
	await _test_t03_fifth_rejected()

	print("")
	print("MP1_RESULT checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: %s" % message)
	else:
		print("PASS: %s" % message)

func _test_t01_basic_connection() -> void:
	print("\n[T01] Host + client localhost connection")
	# Test session manager registration logic without actual network
	var session := SessionManager.new()
	root.add_child(session)

	var host_player_id := session.register_host_player()
	_check(host_player_id == 1, "T01: Host gets player_id 1")

	var join_result := session.try_join_peer(2, &"astra")
	_check(join_result.accepted == true, "T01: Second peer joins successfully")
	_check(join_result.player_id == 2, "T01: Second peer gets unique player_id 2")
	_check(session.get_player_count() == 2, "T01: Player count is 2")

	session.queue_free()

func _test_t02_max_players() -> void:
	print("\n[T02] 4 total players join")
	var session := SessionManager.new()
	root.add_child(session)

	session.register_host_player()  # Player 1 (host)
	var r2 := session.try_join_peer(2, &"astra")  # Player 2
	var r3 := session.try_join_peer(3, &"viridian")  # Player 3
	var r4 := session.try_join_peer(4, &"graveshade")  # Player 4

	_check(r2.accepted == true, "T02: 2nd player accepted")
	_check(r3.accepted == true, "T02: 3rd player accepted")
	_check(r4.accepted == true, "T02: 4th player accepted (exact max)")
	_check(session.get_player_count() == 4, "T02: Total 4 players")
	_check(session.is_full() == true, "T02: Session reports full")

	session.queue_free()

func _test_t03_fifth_rejected() -> void:
	print("\n[T03] 5th participant rejected safely")
	var session := SessionManager.new()
	root.add_child(session)

	session.register_host_player()
	session.try_join_peer(2, &"astra")
	session.try_join_peer(3, &"viridian")
	session.try_join_peer(4, &"graveshade")

	var r5 := session.try_join_peer(5, &"tofu")
	_check(r5.accepted == false, "T03: 5th player rejected")
	_check(r5.reason.contains("full"), "T03: Rejection reason mentions 'full'")
	_check(session.get_player_count() == 4, "T03: Player count remains 4")

	session.queue_free()
