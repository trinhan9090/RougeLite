extends SceneTree

var _checks: int = 0
var _failures: int = 0
var _actors: Array[Actor] = []

func _initialize() -> void:
	call_deferred("_run")

func _actor(id: int, position: Vector2, team: int = 2) -> Actor:
	var actor := Actor.new()
	actor.actor_id = id
	actor.position = position
	actor.team = team
	actor.stats_definition = ActorStatDefinition.new()
	root.add_child(actor)
	_actors.append(actor)
	return actor

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", label)
	else:
		_failures += 1
		printerr("FAIL ", label)

func _run() -> void:
	var source := _actor(1, Vector2.ZERO, 1)
	var far := _actor(3, Vector2(100, 0))
	var near := _actor(2, Vector2(40, 0))
	_check(TargetingService.nearest(source, [], 100) == null, "empty target set")
	_check(TargetingService.nearest(source, [far, near], 100) == near, "nearest within range")
	_check(TargetingService.nearest(source, [far], 100) == far, "exact range included")
	_check(TargetingService.nearest(source, [far], 99.99) == null, "outside range excluded")
	var tie := _actor(4, Vector2(-40, 0))
	_check(TargetingService.nearest(source, [tie, near], 100) == near, "tie uses stable ID independent of array order")
	tie.position = Vector2(-40.0001, 0)
	tie.actor_id = 0
	_check(TargetingService.nearest(source, [near, tie], 100) == near, "near-equal distances still select strictly nearest")
	near.health.commit_resolved_hp(0)
	_check(TargetingService.nearest(source, [near, far], 100) == far, "dead ignored")
	var ally := _actor(5, Vector2(1, 0), 1)
	_check(TargetingService.nearest(source, [ally, source, null], 100) == null, "self allied null excluded")
	var stale_candidates: Array[Actor] = [tie]
	tie.queue_free()
	_check(TargetingService.nearest(source, stale_candidates, 100) == null, "queued target excluded")
	await process_frame
	_check(TargetingService.nearest(source, stale_candidates, 100) == null, "freed target excluded")
	for actor in _actors:
		if is_instance_valid(actor):
			actor.queue_free()
	await process_frame
	print("RESULT targeting: checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
