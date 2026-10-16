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

func _sample(generator: RandomNumberGenerator, count: int) -> Array[int]:
	var result: Array[int] = []
	for index in range(count):
		result.append(generator.randi())
	return result

func _run() -> void:
	for seed_value: int in [0, 20261015, -42, 9223372036854775807]:
		var left := RunState.new(seed_value)
		var right := RunState.new(seed_value)
		for stream_name in RunRng.STREAM_NAMES:
			_check(_sample(left.rng.stream(stream_name), 40) == _sample(right.rng.stream(stream_name), 40), "same seed/state sequence %d/%s" % [seed_value, stream_name])
	var baseline := RunRng.new(20261015)
	var perturbed := RunRng.new(20261015)
	_sample(perturbed.stream(&"combat"), 1000)
	for stream_name: StringName in [&"maps", &"obstacles", &"spawns", &"offers"]:
		_check(_sample(baseline.stream(stream_name), 30) == _sample(perturbed.stream(stream_name), 30), "combat consumption does not perturb %s" % stream_name)
	var saved: Dictionary[StringName, int] = perturbed.snapshot()
	var expected: Array[int] = _sample(perturbed.stream(&"offers"), 100)
	_check(perturbed.restore(saved), "RNG state restore accepted")
	_check(expected == _sample(perturbed.stream(&"offers"), 100), "restored state continues exact sequence")
	var before := perturbed.snapshot()
	_check(not perturbed.restore({&"maps": 123}), "partial restore rejected")
	_check(before == perturbed.snapshot(), "failed restore is atomic")
	var different := RunRng.new(20261016)
	var original := RunRng.new(20261015)
	_check(_sample(different.stream(&"maps"), 30) != _sample(original.stream(&"maps"), 30), "different seeds differ")
	var named := RunRng.new(20261015)
	_check(_sample(named.stream(&"maps"), 30) != _sample(named.stream(&"offers"), 30), "different named streams differ")
	_check(named.stream(&"typo") == null, "unknown stream fails closed")
	var first := RunState.new(7)
	var second := RunState.new(7)
	first.run_upgrades[&"stat.damage"] = 5
	first.current_xp = 70
	_check(second.run_upgrades.is_empty() and second.current_xp == 0, "run state isolated")
	_check(second.current_level == 1 and second.alive and second.boss_gate_state == &"IDLE", "run initializes deterministically")
	_check(second.debug_summary().contains("Seed: 7"), "seed is available for debug display")
	print("RESULT RNG: checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
