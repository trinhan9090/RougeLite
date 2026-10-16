extends SceneTree
var failures: int = 0
func _initialize() -> void: call_deferred("run_tests")
func run_tests() -> void:
	var arena := ArenaGeometry.new()
	root.add_child(arena)
	var target := (load("res://scenes/characters/player.tscn") as PackedScene).instantiate() as PlayerActor
	root.add_child(target)
	target.set_physics_process(false)
	target.position = Vector2.ZERO
	var enemies: Array[EnemyActor] = []
	for point: Vector2 in [Vector2(500,0),Vector2(500,100),Vector2(420,-150),Vector2(-650,-180),Vector2(-100,500)]:
		var enemy := (load("res://scenes/enemies/chaser.tscn") as PackedScene).instantiate() as EnemyActor
		enemy.position = point
		root.add_child(enemy)
		enemy.set_target(target)
		enemy.navigation = arena.navigation_direction
		enemies.append(enemy)
	for i in range(900): await physics_frame
	for enemy in enemies:
		if enemy.position.distance_to(target.position) > 45:
			failures += 1
			printerr("FAIL chase stuck at ",enemy.position)
		else: print("PASS chase reached player ",enemy.position)
	# A player standing beside a wall can occupy a conservatively solid grid
	# cell. Enemies on the other side must go around, not chase through it.
	target.position = Vector2(285,0)
	enemies[0].position = Vector2(500,0)
	for i in range(600): await physics_frame
	if enemies[0].position.distance_to(target.position) > 45:
		failures += 1
		printerr("FAIL wall-adjacent target unreachable ",enemies[0].position)
	else: print("PASS wall-adjacent target reached")
	arena.queue_free()
	target.queue_free()
	for enemy in enemies: enemy.queue_free()
	await process_frame
	print("RESULT navigation checks=6 failures=",failures)
	quit(0 if failures == 0 else 1)
