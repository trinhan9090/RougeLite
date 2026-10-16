class_name ReleaseSmoke
extends Node
## Opt-in packaged-build acceptance, invoked only with -- --smoke-release.
func _ready() -> void: call_deferred("run")
func run() -> void:
	if OS.get_cmdline_user_args().has("--pack-check"):
		if ResourceLoader.exists("res://content/characters/vex_visual_frames.tres") or ResourceLoader.exists("res://content/characters/boros_visual_frames.tres"):
			fail("unverified legacy art leaked into release")
			return
	if OS.get_cmdline_user_args().has("--pack-check") and FileAccess.file_exists("res://tests/unit/test_content.gd"):
		fail("source test files leaked into packaged resource namespace")
		return
	for identity in ["astra","vex","boros"]:
		var scene := load("res://scenes/run/combat_run.tscn") as PackedScene
		var game := scene.instantiate() as CombatRunRoot
		game.loadout_id = StringName("loadout."+identity)
		get_tree().root.add_child(game)
		game._spawn_clock = 99999
		game.player.invulnerability_left = 99999
		for level in range(2,12):
			game.progression.add_xp(game.progression.curve.threshold(game.state.current_level)-game.state.current_xp)
			if game._offer.size() != 3: fail("missing offer"); return
			game.request_upgrade(0)
			if game.state.boss_gate_state == &"PENDING":
				for attempt in range(30):
					if game.state.boss_gate_state == &"ACTIVE": break
					game._spawn_boss()
				if not is_instance_valid(game.boss): fail("missing boss"); return
				var rank := SkillRankDefinition.new()
				rank.damage = 999999
				rank.damage_type = "TRUE"
				game.combat.hit(game.player,game.boss,rank,game.combat.next_context(game.player,&"smoke.damage"))
				await get_tree().process_frame
				await get_tree().process_frame
				await get_tree().process_frame
		if game.state.current_level < 11 or game.bosses_defeated != 1 or game.skills.runtime_for(4).rank < 1: fail("bad progression"); return
		print("RELEASE_PROFILE_OK ",identity)
		game.queue_free()
		await get_tree().process_frame
	print("RELEASE_SMOKE_OK profiles=3 boss_victories=3")
	get_tree().quit()
func fail(message: String) -> void:
	push_error("RELEASE_SMOKE_FAILED " + message)
	get_tree().quit(1)
