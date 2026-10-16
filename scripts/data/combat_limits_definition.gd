class_name CombatLimitsDefinition
extends Resource
@export var chain_depth: int = 3
@export var secondary_procs: int = 32
@export var projectiles_per_root: int = 64
@export var reflect_boss_hp_cap: float = 0.01

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if chain_depth < 1 or secondary_procs < 1 or projectiles_per_root < 1 or not is_finite(reflect_boss_hp_cap) or reflect_boss_hp_cap <= 0 or reflect_boss_hp_cap > 1: errors.append("invalid combat safety limits")
	return errors
