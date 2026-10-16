extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS ", label)
	else:
		failures += 1
		printerr("FAIL ", label)
func frames(count: int) -> void:
	for index in range(count): await physics_frame
func run_tests() -> void:
	var original: Node = root.get_node("AppSettings")
	root.remove_child(original)
	original.free()
	var settings := SettingsService.new("user://m2-scene-test.cfg")
	settings.name = "AppSettings"
	root.add_child(settings)
	settings.set_mode(&"MANUAL")
	for identity in ["astra", "vex", "boros"]:
		var run := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
		run.loadout_id = StringName("loadout." + identity)
		root.add_child(run)
		run._spawn_clock = 999
		await frames(3)
		var enemy: EnemyActor = run.spawn_enemy()
		check(enemy != null, "%s M2 scene spawned actual target" % identity)
		enemy.position = Vector2(80, 0)
		enemy.set_physics_process(false)
		enemy.health.maximum = 30000
		enemy.health.current = 30000
		run.player.stats.crit_chance = 0
		for slot in range(1, 4):
			var level: int = [3,6,9][slot - 1]
			run.state.current_level = level - 1
			run.progression.add_xp(run.progression.curve.threshold(level - 1))
			check(paused and run.skills.runtime_for(slot).rank == 1 and run._offer.size() == 3, "%s free slot%d unlock before modal" % [identity,slot])
			run.request_upgrade(0)
			check(not paused and run.state.run_phase == &"RUNNING", "%s bound card commits/resumes slot%d" % [identity,slot])
			var runtime: SkillRuntime = run.skills.runtime_for(slot)
			var sequence: int = runtime.cast_sequence_number
			await frames(3)
			check(runtime.cast_sequence_number == sequence, "%s Manual slot%d does not autocast" % [identity,slot])
			check(run.skills.request_cast(slot, enemy.position), "%s manual slot%d accepts common executor" % [identity,slot])
			check(runtime.cast_sequence_number == sequence + 1 and runtime.cooldown_remaining > 0, "%s slot%d commits cooldown once" % [identity,slot])
			await frames(25)
		check(run._basic.cooldown_left > 0, "%s basic stays automatic in Manual mode" % identity)
		run.request_pause()
		var cooldown: float = run.skills.runtime_for(1).cooldown_remaining
		await create_timer(.05, true).timeout
		check(run.skills.runtime_for(1).cooldown_remaining == cooldown, "%s modal freezes active cooldown" % identity)
		run.request_pause()
		if identity == "astra" and OS.get_cmdline_user_args().has("--capture-m2") and DisplayServer.get_name() != "headless":
			var skill: SkillRuntime = run.skills.runtime_for(1)
			for name in ["projectile_split", "multishot", "echo_cast", "explosion_on_hit"]:
				var definition := load("res://content/augments/mechanics/%s.tres" % name) as AugmentDefinition
				run.augments.apply_bound(definition, skill)
			skill.advance_cooldown(100)
			enemy.position = run.player.position + Vector2(260, 120)
			check(run._arena.point_clear(enemy.position, 14) and run.combat.unobstructed(run.player.position, enemy.position), "graphical fixture target has clear collision and line of sight")
			run.skills.request_cast(1, enemy.position)
			await frames(8)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/evidence/m2-gameplay.png")
			run._on_level_applied(9)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/evidence/m2-upgrades.png")
			paused = false
		run.queue_free()
		await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://m2-scene-test.cfg"))
	print("RESULT M2 scenes: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
