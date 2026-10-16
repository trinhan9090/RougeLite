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

func _run() -> void:
	for profile_id: String in ["astra", "vex", "boros"]:
		var profile := load("res://content/characters/%s_loadout.tres" % profile_id) as CombatLoadoutDefinition
		_check(profile.validate().is_empty(), "loadout validates %s" % profile_id)
		var player := (load("res://scenes/characters/player.tscn") as PackedScene).instantiate() as PlayerActor
		player.stats_definition = profile.stats
		root.add_child(player)
		player.stats.crit_chance = 0.0
		var enemy := (load("res://scenes/enemies/chaser.tscn") as PackedScene).instantiate() as EnemyActor
		enemy.position = Vector2(60, 0)
		root.add_child(enemy)
		enemy.set_physics_process(false)
		var combat := CombatService.new()
		combat.rng = RunRng.new(77).stream(&"combat")
		root.add_child(combat)
		var controller := AttackController.new(player, profile.basic_attack)
		_check(not controller.step(0, [], combat) and controller.cooldown_left == 0.0, "no target consumes no cooldown %s" % profile_id)
		await physics_frame
		await physics_frame
		_check(controller.step(0, [enemy], combat), "basic fires %s" % profile_id)
		_check(not controller.step(0, [enemy], combat), "cooldown prevents duplicate attack %s" % profile_id)
		for index in range(20):
			await physics_frame
		var expected: float = profile.basic_attack.rank_scaling[0].damage
		_check(is_equal_approx(35.0 - enemy.health.current, expected), "actual physics hit damage %s" % profile_id)
		_check(profile.stats.crit_chance != 0.0, "runtime crit override does not mutate profile %s" % profile_id)
		player.queue_free()
		enemy.queue_free()
		combat.queue_free()
		await process_frame
	print("RESULT attacks: checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
