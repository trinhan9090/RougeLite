class_name SkillBehaviorDefinition
extends Resource
## Optional rank graph operations, independent of actor identities.
@export var status: StatusEffectDefinition
@export var can_crit: bool = false
@export var crit_bonus: float = 0.0
@export var crit_pierce: int = 0
@export var shot_interval: float = 0.0
@export var boss_bonus: float = 0.0
@export var max_hp_damage: float = 0.0
@export var max_hp_boss_cap: float = 30.0
@export var mark_duration: float = 0.0
@export var mark_bonus: float = 0.0
@export var death_damage: float = 0.0
@export var death_radius: float = 80.0
@export var move_bonus: float = 0.0
@export var attack_bonus: float = 0.0
@export var buff_duration: float = 3.0
@export var extra_basic: int = 0
@export var kill_refund: float = 0.0
@export var shield_reduction: float = 0.0
@export var reflect_fraction: float = 0.0
@export var blocked_pulse: float = 0.0
@export var blocked_interval: float = 1.0
@export var expire_damage: float = 0.0
@export var expire_radius: float = 110.0
@export var expire_heal_fraction: float = 0.0
@export var expire_heal_cap: float = 60.0
@export var repeat_delay: float = 0.0
@export var repeat_scale: float = 0.0
@export var trail_duration: float = 0.0
@export var trail_damage: float = 0.0
@export var burn_duration: float = 0.0
@export var burn_damage: float = 0.0
@export var bounce_chance: float = 0.0
@export var bounce_scale: float = 0.5
@export var hp_bonus: float = 0.0
@export var range_bonus: float = 0.0
@export var basic_pulse_scale: float = 0.0
@export var basic_pulse_radius: float = 85.0

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for field in get_property_list():
		if field.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and field.type in [TYPE_FLOAT, TYPE_INT]:
			var value: float = get(field.name)
			if not is_finite(value) or value < 0: errors.append("invalid rank behavior %s" % field.name)
	if status != null: errors.append_array(status.validate())
	return errors
