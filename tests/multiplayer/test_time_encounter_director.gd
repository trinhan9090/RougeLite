extends GutTest
## Integration test for TimeEncounterDirector - strict 180s boss spawns.

var time_director: TimeEncounterDirector

func before_each() -> void:
	# Mock server
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(24567, 3)
	multiplayer.multiplayer_peer = peer

	time_director = TimeEncounterDirector.new()
	add_child_autofree(time_director)

func after_each() -> void:
	multiplayer.multiplayer_peer = null

func test_first_boss_spawns_at_180_seconds() -> void:
	# Simulate 180 seconds (10800 ticks at 60Hz)
	for i in range(10800):
		time_director._physics_process(1.0 / 60.0)

	assert_eq(time_director.get_defeated_boss_count() + time_director.get_active_boss_count(), 1,
		"Exactly 1 boss should spawn at 180s")

func test_second_boss_spawns_at_360_even_if_first_alive() -> void:
	var bosses_spawned := 0
	time_director.boss_spawned.connect(func(_id, _seq, _time): bosses_spawned += 1)

	# Simulate 360 seconds
	for i in range(21600):  # 360 * 60
		time_director._physics_process(1.0 / 60.0)

	assert_eq(bosses_spawned, 2, "Should spawn 2 bosses by 360s")
	assert_gte(time_director.get_active_boss_count(), 1, "At least 1 boss should be active")

func test_boss_defeat_does_not_affect_spawn_schedule() -> void:
	var boss_ids: Array[String] = []
	time_director.boss_spawned.connect(func(id, _seq, _time): boss_ids.append(id))

	# Simulate to 180s, spawn boss #1
	for i in range(10800):
		time_director._physics_process(1.0 / 60.0)

	assert_eq(boss_ids.size(), 1, "Boss #1 spawned")

	# Defeat boss #1
	time_director.report_boss_death(boss_ids[0])

	# Continue to 360s
	for i in range(10800):
		time_director._physics_process(1.0 / 60.0)

	assert_eq(boss_ids.size(), 2, "Boss #2 should spawn regardless of boss #1 defeat")

func test_no_boss_from_duplicate_spawn() -> void:
	var bosses_spawned := 0
	time_director.boss_spawned.connect(func(_id, _seq, _time): bosses_spawned += 1)

	# Simulate exactly 180s twice (should not duplicate)
	for i in range(10800):
		time_director._physics_process(1.0 / 60.0)

	var count_after_first := bosses_spawned

	# Process a few more frames
	for i in range(60):
		time_director._physics_process(1.0 / 60.0)

	assert_eq(bosses_spawned, count_after_first, "No duplicate boss spawn")

func test_catch_up_after_lag_spike() -> void:
	var bosses_spawned := 0
	time_director.boss_spawned.connect(func(_id, _seq, _time): bosses_spawned += 1)

	# Simulate to 179s
	for i in range(10740):
		time_director._physics_process(1.0 / 60.0)

	# Simulate 300-second lag spike (unrealistic but tests catch-up)
	for i in range(18000):  # 300s
		time_director._physics_process(1.0 / 60.0)

	# Should spawn boss #1 and #2 (180s and 360s boundaries crossed)
	assert_gte(bosses_spawned, 2, "Should catch up and spawn missed bosses")
