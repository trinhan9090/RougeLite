class_name ShieldInstance
extends RefCounted

var remaining: float
var duration_left: float
var absorbed: float = 0
var context: CombatContext
var behavior: SkillBehaviorDefinition
var pulse_left: float = 0

func _init(amount: float, duration: float) -> void:
	remaining = maxf(0.0, amount)
	duration_left = maxf(0.0, duration)
