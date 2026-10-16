extends SceneTree

var _failures: int = 0
var _checks: int = 0
var _deaths: int = 0

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
	var lab := (load("res://scenes/run/movement_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	var player := lab.get_node("Player") as PlayerActor
	var enemy := (load("res://scenes/enemies/chaser.tscn") as PackedScene).instantiate() as EnemyActor
	enemy.position = Vector2(-200, 0)
	lab.add_child(enemy)
	enemy.set_target(player)
	_check(enemy.health.current == 35.0 and enemy.stats.move_speed == 110.0 and enemy.team == 2, "enemy stats loaded from data")
	var start: float = enemy.position.distance_to(player.position)
	for index in range(30):
		await physics_frame
	_check(enemy.position.distance_to(player.position) < start - 40.0, "enemy physically chases target")
	enemy.died.connect(func(_actor: Actor) -> void: _deaths += 1)
	enemy.health.commit_resolved_hp(0.0)
	enemy.health.commit_resolved_hp(0.0)
	_check(_deaths == 1, "actor emits death exactly once")
	_check(not enemy.is_physics_processing() and enemy.collision_layer == 0, "dead actor stops physics/collision")
	_check(enemy.definition.stats.max_hp == 35.0, "runtime lifecycle does not mutate definition")
	lab.queue_free()
	await process_frame
	print("RESULT actors: checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
