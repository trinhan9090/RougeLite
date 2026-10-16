class_name DamagePacket
extends RefCounted

var base_damage: float = 0.0
var damage_type: StringName = &"PHYSICAL"
var can_crit: bool = false
var crit_bonus: float = 0.0
var scale_with_stats: bool = true
var status: StatusEffectDefinition
var context: CombatContext = CombatContext.new()
