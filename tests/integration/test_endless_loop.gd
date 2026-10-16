extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks += 1
	if value: print("PASS ",label)
	else:
		failures += 1
		printerr("FAIL ",label)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run_tests() -> void:
	for identity in ["astra","vex","boros"]:
		var run := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
		run.loadout_id = StringName("loadout."+identity)
		root.add_child(run)
		run._spawn_clock = 99999
		run.player.invulnerability_left = 99999
		var visited: Array[StringName] = [run.state.map_id]
		var choices: int = 0
		while run.state.current_level < 41 and choices < 80:
			run.progression.add_xp(run.progression.curve.threshold(run.state.current_level)-run.state.current_xp)
			check(run.state.run_phase == &"UPGRADE" and run._offer.size() == 3,"%s level%d valid3-choice transaction" % [identity,run.state.current_level])
			if run.state.current_level == 10:
				var previous: Array[String] = []
				for option in run._offer: previous.append(option.key())
				run.request_reroll()
				check(run.state.reroll_tokens == 0 and run._offer.all(func(option: UpgradeOption) -> bool: return not previous.has(option.key())),"earned reroll replaces3 cards without repeats")
			run.request_upgrade(0)
			choices += 1
			if run.state.boss_gate_state == &"PENDING":
				run._warning_left = 0
				for attempt in range(20):
					if run.state.boss_gate_state == &"ACTIVE": break
					run._spawn_boss()
				check(is_instance_valid(run.boss) and run.state.boss_gate_state == &"ACTIVE","%s real boss at%d" % [identity,run.state.current_level])
				if not is_instance_valid(run.boss): break
				check(not run.gate.request(run.state.current_level),"active gate rejects duplicate boss")
				var before: int = run.state.current_level
				run.progression.add_xp(13)
				check(run.state.current_level == before and run.state.xp_pending_during_boss >= 13,"boss banks XP")
				var map_before: StringName = run.state.map_id
				var upgrades: Dictionary = run.state.run_upgrades.duplicate()
				var lethal := SkillRankDefinition.new()
				lethal.damage = 999999
				lethal.damage_type = "TRUE"
				run.combat.hit(run.player,run.boss,lethal,run.combat.next_context(run.player,&"test.accelerated_damage"))
				await process_frame
				await process_frame
				await process_frame
				check(run.state.map_id != map_before and run.state.run_upgrades == upgrades and run.player.invulnerability_left > 0,"victory changes map, preserves upgrades, grants immunity")
				check(run.state.boss_gate_state == &"IDLE" and run.state.xp_pending_during_boss == 0,"transition releases bank exactly once")
				visited.append(run.state.map_id)
				run._spawn_clock = 99999
				run.player.invulnerability_left = 99999
		check(run.state.current_level >= 41 and run.bosses_defeated == 4 and run.maps_visited == 5,"%s endless reaches41 with four real boss deaths/transitions" % identity)
		check(visited[0] != visited[1] and visited[1] != visited[2] and visited[0] != visited[2],"map bag visits all3 before repeat")
		check(run.skills.runtime_for(4).rank >= 1,"ultimate unlocked after first real boss")
		# Losing on the lethal boss frame takes precedence over deferred victory.
		run.state.current_level = 50
		run.gate.request(50)
		for attempt in range(30):
			if is_instance_valid(run.boss): break
			run._spawn_boss()
		check(is_instance_valid(run.boss),"simultaneous-death fixture has real boss")
		if is_instance_valid(run.boss):
			run.boss.health.commit_resolved_hp(0)
			run.player.health.commit_resolved_hp(0)
			await process_frame
			check(run.state.run_phase == &"DEAD" and run.bosses_defeated == 4,"simultaneous death prevents victory/transition")
		paused = false
		run.queue_free()
		await process_frame
	print("RESULT endless loop: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
