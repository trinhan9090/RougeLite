class_name RunRng
extends RefCounted
## One run seed, independent named streams. Explicit stable derivation avoids
## process-global RNG and version-dependent String.hash(). Replay pins Godot.

const STREAM_NAMES: Array[StringName] = [&"maps", &"obstacles", &"spawns", &"offers", &"combat"]
var _seed: int
var _streams: Dictionary[StringName, RandomNumberGenerator] = {}

func _init(run_seed: int = 0) -> void:
	_seed = run_seed
	for stream_name in STREAM_NAMES:
		var generator := RandomNumberGenerator.new()
		generator.seed = _derive_seed(run_seed, stream_name)
		_streams[stream_name] = generator

func stream(stream_name: StringName) -> RandomNumberGenerator:
	return _streams.get(stream_name)

func snapshot() -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	for stream_name in STREAM_NAMES:
		result[stream_name] = _streams[stream_name].state
	return result

func restore(states: Dictionary[StringName, int]) -> bool:
	if states.size() != STREAM_NAMES.size():
		return false
	for stream_name in STREAM_NAMES:
		if not states.has(stream_name):
			return false
	for stream_name in STREAM_NAMES:
		_streams[stream_name].state = states[stream_name]
	return true

static func _derive_seed(run_seed: int, stream_name: StringName) -> int:
	var value: int = 5381
	for byte in (str(run_seed) + ":" + String(stream_name)).to_utf8_buffer():
		value = (value * 131 + byte) % 2147483647
	return value
