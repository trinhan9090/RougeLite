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

func _run() -> void:
	for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		_check(is_equal_approx(MovementController.velocity_for(direction, 240).length(), 240.0), "normalized movement %s" % direction)
	_check(MovementController.velocity_for(Vector2.ZERO, 240) == Vector2.ZERO, "idle velocity zero")
	var lab := (load("res://scenes/run/movement_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	var player := lab.get_node("Player") as PlayerActor
	await _frames(3)
	Input.action_press(&"move_right")
	await _frames(30)
	Input.action_release(&"move_right")
	var cardinal: float = player.position.length()
	player.position = Vector2.ZERO
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	await _frames(30)
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	_check(absf(player.position.length() - cardinal) < 5.0, "real WASD diagonal displacement equals cardinal")
	player.position = Vector2(250, 0)
	Input.action_press(&"move_right")
	await _frames(30)
	_check(player.position.x <= 286.1 and player.position.x > 270.0, "physics obstacle collision")
	player.position = Vector2(1080, 0)
	await _frames(30)
	Input.action_release(&"move_right")
	_check(player.position.x <= 1086.1, "physics arena boundary collision")
	lab.queue_free()
	await process_frame
	print("RESULT movement: checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
