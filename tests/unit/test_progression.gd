extends SceneTree

var _checks: int = 0
var _failures: int = 0
var _levels: Array[int] = []
var _collections: int = 0

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
	var curve := load("res://content/progression/default.tres") as ProgressionDefinition
	_check(curve.threshold(1) == 25 and curve.threshold(2) == 39, "XP curve exact first thresholds")
	var state := RunState.new(1)
	var manager := LevelManager.new(state, curve)
	manager.level_applied.connect(func(level: int) -> void: _levels.append(level))
	var total: int = 0
	for level in range(1, 5):
		total += curve.threshold(level)
	manager.add_xp(total)
	_check(state.current_level == 2 and manager.awaiting_choice, "batched XP advances one level and queues choices")
	manager.add_xp(1)
	_check(state.current_level == 2, "pending choice cannot skip level")
	for index in range(4):
		manager.acknowledge_choice()
	_check(_levels == [2, 3, 4, 5] and state.current_xp == 1, "all queued levels settle sequentially without losing XP")
	_check(not manager.acknowledge_choice(), "duplicate acknowledgement ignored")
	manager.add_xp(-50)
	_check(state.current_xp == 1, "negative XP ignored")
	state.boss_gate_state = &"ACTIVE"
	manager.add_xp(100)
	_check(state.xp_pending_during_boss == 100 and state.current_level == 5, "boss-active XP is banked")
	state.alive = false
	manager.add_xp(100)
	_check(state.xp_pending_during_boss == 100, "dead run gains no XP")
	var player := (load("res://scenes/characters/player.tscn") as PackedScene).instantiate() as PlayerActor
	root.add_child(player)
	var orb := XpOrb.new()
	orb.configure(player, 6, curve)
	orb.collected.connect(func(amount: int) -> void: _collections += amount)
	root.add_child(orb)
	_check(orb.consume_once() and not orb.consume_once() and _collections == 6, "orb can be collected exactly once")
	await process_frame
	var magnet := XpOrb.new()
	magnet.configure(player, 6, curve)
	magnet.position = Vector2(70, 0)
	magnet.collected.connect(func(amount: int) -> void: _collections += amount)
	root.add_child(magnet)
	for index in range(20):
		await physics_frame
	_check(_collections == 12 and not is_instance_valid(magnet), "orb magnet physically moves and collects")
	player.queue_free()
	await process_frame
	print("RESULT progression: checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
