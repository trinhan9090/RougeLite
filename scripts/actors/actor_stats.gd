class_name ActorStats
extends RefCounted
## Per-actor scalars copied from immutable content, never shared mutable Resources.

var max_hp: float
var move_speed: float
var armor: float
var magic_resistance: float = 0.0
var crit_chance: float
var crit_multiplier: float
var damage_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
var cooldown_reduction: float = 0.0
var pickup_radius: float = 90.0

func _init(definition: ActorStatDefinition) -> void:
	max_hp = definition.max_hp
	move_speed = definition.move_speed
	armor = definition.armor
	crit_chance = definition.crit_chance
	crit_multiplier = definition.crit_multiplier
