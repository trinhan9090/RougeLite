class_name CombatEventBus
extends RefCounted

signal damage_applied(context: CombatContext, result: DamageResult)
signal hit_resolved(context: CombatContext, result: DamageResult)
signal critical_applied(context: CombatContext, result: DamageResult)
signal actor_killed(context: CombatContext, result: DamageResult)
