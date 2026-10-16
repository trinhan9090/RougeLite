class_name StatusController
extends RefCounted
## Refresh strongest/duration per status kind. Boss hard CC becomes stagger.

var _statuses: Dictionary[StringName, Vector2] = {}
var _stagger_lock: float = 0.0

func apply(definition: StatusEffectDefinition, boss: bool = false) -> void:
	if definition == null or definition.kind not in ["root", "slow", "stun"] or not is_finite(definition.duration) or definition.duration <= 0.0 or not is_finite(definition.strength):
		return
	var kind := StringName(definition.kind)
	var duration: float = definition.duration
	if boss and kind in [&"root", &"stun"]:
		if _stagger_lock > 0.0:
			return
		kind = &"stun"
		duration = 0.15
		_stagger_lock = 4.0
	var current: Vector2 = _statuses.get(kind, Vector2.ZERO)
	_statuses[kind] = Vector2(maxf(duration, current.x), maxf(clampf(definition.strength, 0.0, 0.65), current.y))

func advance(delta: float) -> void:
	_stagger_lock = maxf(0.0, _stagger_lock - delta)
	for kind: StringName in _statuses.keys():
		var entry: Vector2 = _statuses[kind]
		entry.x -= delta
		if entry.x <= 0.0:
			_statuses.erase(kind)
		else:
			_statuses[kind] = entry

func stunned() -> bool:
	return _statuses.has(&"stun")

func movement_factor() -> float:
	if stunned() or _statuses.has(&"root"):
		return 0.0
	var slow: Vector2 = _statuses.get(&"slow", Vector2.ZERO)
	return maxf(0.35, 1.0 - slow.y)
