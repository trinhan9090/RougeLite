extends SceneTree

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

func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func _capture(path: String) -> void:
	if OS.get_cmdline_user_args().has("--capture-combat") and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(path)

func _run() -> void:
	var run := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(run)
	run._spawn_clock = 999
	_check(run.state.current_level == 1 and run.player.health.current == 130.0, "combat run initializes player/domain")
	await _frames(3)
	var enemy: EnemyActor = run.spawn_enemy()
	_check(enemy != null and enemy.position.distance_to(run.player.position) >= 550.0, "runtime enemy spawns beyond exclusion radius")
	if enemy != null:
		enemy.position = Vector2(60, 0) # Test fixture relocation, not the spawn algorithm.
	await _frames(130)
	_check(run.kills >= 1 and run.state.current_xp >= 6, "real auto attack -> death -> XP orb -> pickup")
	var hp_bar := run.presentation.find_child("HpBar", true, false) as ProgressBar
	var xp_bar := run.presentation.find_child("XpBar", true, false) as ProgressBar
	_check(hp_bar != null and xp_bar != null and xp_bar.value >= 6, "HUD presents actual HP and XP")
	run.request_pause()
	var elapsed: float = run.state.elapsed_simulation_seconds
	var position: Vector2 = run.player.position
	await create_timer(0.1, true).timeout
	_check(paused and run.state.elapsed_simulation_seconds == elapsed and run.player.position == position, "pause stops domain and physical world")
	run.request_pause()
	run.progression.add_xp(run.progression.curve.threshold(1) - run.state.current_xp)
	_check(paused and run.state.run_phase == &"UPGRADE" and run._offer.size() == 3, "level up pauses world and offers exactly three")
	await _capture("res://docs/evidence/m1-upgrade.png")
	var picked_option: UpgradeOption = run._offer[0]
	var picked: StringName = StringName(picked_option.key()) if picked_option.target_skill_id != &"" else picked_option.id
	var card := run.presentation.find_child("UpgradeCard0", true, false) as Button
	card.pressed.emit()
	_check(not paused and run.state.run_upgrades.get(picked, 0) == 1, "actual card signal commits one upgrade and resumes")
	run.request_upgrade(0)
	_check(run.state.run_upgrades.size() == 1, "duplicate stale choice rejected")
	var attacker: EnemyActor = run.spawn_enemy()
	var lethal := DamagePacket.new()
	lethal.base_damage = 9999
	lethal.damage_type = &"TRUE"
	run.combat.resolver.resolve(lethal, attacker, run.player, run.state.rng.stream(&"combat"))
	_check(paused and run.state.run_phase == &"DEAD" and not run.state.alive, "lethal combat enters game over")
	run.request_retry()
	await process_frame
	await process_frame
	await process_frame
	_check(run.state.alive and run.state.current_level == 1 and run.state.run_upgrades.is_empty() and run.run_seed == 20261015, "retry resets run state and keeps seed")
	run._spawn_clock = 999
	for index in range(5):
		run.spawn_enemy()
	await _frames(120)
	await _capture("res://docs/evidence/m1-combat.png")
	run.state.current_level = 9
	run.state.current_xp = 0
	run.progression.add_xp(run.progression.curve.threshold(9))
	run.request_upgrade(0)
	_check(not paused and run.state.boss_gate_state == &"PENDING", "level10 upgrade schedules real pending boss")
	paused = false
	run.queue_free()
	await process_frame
	print("RESULT combat scene: checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
