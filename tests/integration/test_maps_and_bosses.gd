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
	var config := SpawnDefinition.new()
	check(EnemySpawnDirector.population_cap(config,1) == 40 and EnemySpawnDirector.population_cap(config,36) == 110 and EnemySpawnDirector.population_cap(config,1000) == 110,"adaptive population cap grows40 to110 without exceeding hard cap")
	for name in ["ruined_temple","enchanted_forest","volcanic_arena"]:
		var definition := load("res://content/maps/%s.tres" % name) as MapDefinition
		for seed in range(5):
			var a: Array[Rect2] = MapLayoutGenerator.generate(definition,RunRng.new(seed).stream(&"obstacles"))
			var b: Array[Rect2] = MapLayoutGenerator.generate(definition,RunRng.new(seed).stream(&"obstacles"))
			check(a == b and MapLayoutGenerator.connected(definition,a) and MapLayoutGenerator.clear(Vector2.ZERO,a,250),"%s seed%d deterministic connected safe layout" % [name,seed])
	var target := PlayerActor.new()
	target.actor_id = 1
	target.stats_definition = ActorStatDefinition.new()
	root.add_child(target)
	target.stats.armor = 0
	target.health = Health.new(10000)
	var combat := CombatService.new()
	combat.rng = RunRng.new(37).stream(&"combat")
	root.add_child(combat)
	for name in ["stone_warden","ember_sentinel"]:
		var boss := BossActor.new()
		boss.boss_definition = load("res://content/bosses/%s.tres" % name) as BossDefinition
		boss.combat = combat
		boss.actor_id = 2
		root.add_child(boss)
		boss.set_target(target)
		boss.set_physics_process(false)
		boss.stats.crit_chance = 0
		target.position = Vector2(150,0)
		var before: float = target.health.current
		boss.warn("circle" if name == "stone_warden" else "beam",24,170 if name == "stone_warden" else 37.5,1000,1)
		await frames(30)
		check(target.health.current == before,"%s no damage during telegraph" % name)
		await frames(40)
		check(target.health.current == before-24,"%s telegraphed damage exact24" % name)
		target.position = Vector2(150,0)
		boss.warn("circle" if name == "stone_warden" else "beam",24,170 if name == "stone_warden" else 37.5,1000,1)
		var action: StringName = &"move_right" if name == "stone_warden" else &"move_down"
		Input.action_press(action)
		before = target.health.current
		await frames(70)
		Input.action_release(action)
		check(target.health.current == before and (target.position.x > 200 if name == "stone_warden" else target.position.y > 100),"%s WASD input movement dodges actual telegraphed attack" % name)
		boss.health.current = boss.health.maximum*.3
		boss.attack_clock = 0
		boss._physics_process(0)
		check(boss.attacks_started >= 3,"%s phase2 continues attacks" % name)
		boss.queue_free()
		await process_frame
	combat.queue_free()
	target.queue_free()
	await process_frame
	print("RESULT maps and bosses: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
