extends GutTest
## Integration test for MatchClockAuthority - tick-driven survival timer.

var match_clock: MatchClockAuthority

func before_each() -> void:
	# Mock server
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(24567, 3)
	multiplayer.multiplayer_peer = peer

	match_clock = MatchClockAuthority.new()
	add_child_autofree(match_clock)

func after_each() -> void:
	multiplayer.multiplayer_peer = null

func test_match_starts_at_zero() -> void:
	match_clock.start_match()
	assert_eq(match_clock.get_elapsed_ticks(), 0, "Should start at tick 0")
	assert_true(match_clock.is_running(), "Match should be running")

func test_clock_advances_during_physics() -> void:
	match_clock.start_match()

	for i in range(60):  # 1 second at 60Hz
		match_clock._physics_process(1.0 / 60.0)

	assert_eq(match_clock.get_elapsed_ticks(), 60, "Should advance 60 ticks")
	assert_almost_eq(match_clock.get_elapsed_seconds(), 1.0, 0.1, "Should be ~1 second")

func test_clock_freezes_on_end() -> void:
	match_clock.start_match()

	for i in range(120):
		match_clock._physics_process(1.0 / 60.0)

	match_clock.end_match()

	var frozen_time := match_clock.get_elapsed_seconds()

	for i in range(60):
		match_clock._physics_process(1.0 / 60.0)

	assert_eq(match_clock.get_elapsed_seconds(), frozen_time, "Clock should freeze after end")
	assert_false(match_clock.is_running(), "Match should not be running")

func test_formatted_time_correct() -> void:
	match_clock.start_match()

	for i in range(3600):  # 60 seconds
		match_clock._physics_process(1.0 / 60.0)

	assert_eq(match_clock.get_formatted_time(), "01:00", "Should format as 01:00")
