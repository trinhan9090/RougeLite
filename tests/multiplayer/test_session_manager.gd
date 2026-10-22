extends GutTest
## Unit tests for SessionManager - player roster and authorization.

var session_manager: SessionManager

func before_each() -> void:
	session_manager = SessionManager.new()
	add_child_autofree(session_manager)

func test_register_host_player() -> void:
	var player_id := session_manager.register_host_player(&"astra")
	assert_eq(player_id, 1, "First player should get ID 1")
	assert_eq(session_manager.get_player_count(), 1, "Should have 1 player")

func test_try_join_peer_success() -> void:
	session_manager.register_host_player(&"astra")
	var result := session_manager.try_join_peer(2, &"vex")
	assert_true(result.accepted, "Join should succeed")
	assert_eq(result.player_id, 2, "Should get player ID 2")
	assert_eq(session_manager.get_player_count(), 2, "Should have 2 players")

func test_session_full_rejects_fifth_player() -> void:
	session_manager.register_host_player(&"astra")
	session_manager.try_join_peer(2, &"vex")
	session_manager.try_join_peer(3, &"boros")
	session_manager.try_join_peer(4, &"graveshade")
	var result := session_manager.try_join_peer(5, &"viridian")
	assert_false(result.accepted, "Should reject 5th player")
	assert_eq(session_manager.get_player_count(), 4, "Should remain at 4 players")

func test_duplicate_peer_rejected() -> void:
	session_manager.register_host_player(&"astra")
	session_manager.try_join_peer(2, &"vex")
	var result := session_manager.try_join_peer(2, &"boros")
	assert_false(result.accepted, "Should reject duplicate peer")

func test_remove_peer() -> void:
	session_manager.register_host_player(&"astra")
	session_manager.try_join_peer(2, &"vex")
	session_manager.remove_peer(2, "disconnect")
	assert_eq(session_manager.get_player_count(), 1, "Should have 1 player after removal")

func test_get_player_id_for_peer() -> void:
	var player_id := session_manager.register_host_player(&"astra")
	assert_eq(session_manager.get_player_id_for_peer(1), player_id, "Should return correct player ID")
	assert_eq(session_manager.get_player_id_for_peer(999), -1, "Should return -1 for unknown peer")

func test_get_all_player_ids() -> void:
	session_manager.register_host_player(&"astra")
	session_manager.try_join_peer(2, &"vex")
	session_manager.try_join_peer(3, &"boros")
	var ids := session_manager.get_all_player_ids()
	assert_eq(ids.size(), 3, "Should return 3 player IDs")
	assert_true(1 in ids, "Should contain player 1")
	assert_true(2 in ids, "Should contain player 2")
	assert_true(3 in ids, "Should contain player 3")
