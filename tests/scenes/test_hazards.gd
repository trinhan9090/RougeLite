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
	var run := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(run)
	run._spawn_clock = 99999
	var map := load("res://content/maps/volcanic_arena.tres") as MapDefinition
	run._arena.apply_layout(map,[])
	check(map.validate().is_empty() and map.hazards.size() == 2 and run._arena.spawn_clear(Vector2.ZERO,250),"volcanic hazards preserve safe starting area")
	if map.hazards.is_empty():
		quit(1)
		return
	var point: Vector2 = map.hazards[0].get_center()
	check(not run._arena.spawn_clear(point,16),"spawn validation excludes lava strips")
	run.player.position = point
	var before: float = run.player.health.current
	await frames(30)
	check(run.player.health.current == before,"lava warning grants time before damage")
	await frames(85)
	check(run.player.health.current < before and fmod(before-run.player.health.current,5) == 0,"lava applies5 true damage on simulation ticks")
	run.request_pause()
	before = run.player.health.current
	await create_timer(.15,true).timeout
	check(run.player.health.current == before,"paused lava cannot damage player")
	run.request_pause()
	run.player.position = Vector2.ZERO
	await frames(35)
	check(run.player.health.current == before,"moving out of strip avoids further lava damage")
	run.queue_free()
	await process_frame
	print("RESULT hazards: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
