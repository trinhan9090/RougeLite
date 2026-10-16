class_name Health
extends RefCounted

signal changed(current: float, maximum: float)
signal depleted
var current: float
var maximum: float
var shields: Array[ShieldInstance] = []
var _death_reported: bool = false

func _init(maximum_hp: float) -> void:
	maximum = maximum_hp
	current = maximum_hp

func is_alive() -> bool:
	return current > 0.0

func advance(delta: float) -> void:
	if shields.is_empty(): return
	for shield in shields:
		shield.duration_left -= delta
		shield.pulse_left = maxf(0, shield.pulse_left - delta)
	shields = shields.filter(func(shield: ShieldInstance) -> bool: return shield.duration_left > 0.0 and shield.remaining > 0.0)

func shield_total() -> float:
	var total: float = 0.0
	for shield in shields:
		if shield.duration_left > 0.0:
			total += shield.remaining
	return total

func commit_resolved_hp(new_hp: float) -> void:
	# DamageResolver is the sole caller that subtracts combat damage.
	current = clampf(new_hp, 0.0, maximum)
	changed.emit(current, maximum)
	if current <= 0.0 and not _death_reported:
		_death_reported = true
		depleted.emit()
