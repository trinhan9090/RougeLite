extends GutTest
## Unit tests for NetworkManager - ENet peer lifecycle.

var network_manager: NetworkManager

func before_each() -> void:
	network_manager = NetworkManager.new()
	add_child_autofree(network_manager)

func test_starts_host_successfully() -> void:
	var err := network_manager.start_host(24567)
	assert_eq(err, OK, "Host should start successfully")
	assert_true(network_manager.is_host(), "Should be identified as host")
	assert_true(network_manager.is_active(), "Session should be active")

func test_rejects_duplicate_host_start() -> void:
	network_manager.start_host(24567)
	var err := network_manager.start_host(24568)
	assert_eq(err, ERR_ALREADY_IN_USE, "Should reject duplicate host start")

func test_join_requires_valid_address() -> void:
	var err := network_manager.join_host("", 24567)
	assert_eq(err, ERR_INVALID_PARAMETER, "Should reject empty address")

func test_join_attempt_creates_client() -> void:
	var err := network_manager.join_host("127.0.0.1", 24567)
	# Will fail to connect (no host), but should create client
	assert_eq(err, OK, "Client creation should succeed")

func test_stop_clears_session() -> void:
	network_manager.start_host(24567)
	network_manager.stop()
	assert_false(network_manager.is_active(), "Session should be inactive after stop")
	assert_false(network_manager.is_host(), "Should no longer be host")

func test_get_peer_count_host_only() -> void:
	network_manager.start_host(24567)
	await wait_frames(2)
	var count := network_manager.get_peer_count()
	assert_eq(count, 1, "Host alone should count as 1")
