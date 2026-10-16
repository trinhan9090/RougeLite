class_name SkillRankDefinition
extends Resource

@export var rank: int = 1
@export var cooldown: float = 0.0
@export var damage: float = 0.0
@export_enum("PHYSICAL", "MAGIC", "TRUE") var damage_type: String = "PHYSICAL"
@export var range_px: float = 0.0
@export var radius_px: float = 0.0
@export var duration: float = 0.0
@export var projectile_speed: float = 0.0
@export var projectile_count: int = 1
@export var pierce_count: int = 0
@export var shield: float = 0.0
@export var behavior: SkillBehaviorDefinition

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if behavior != null: errors.append_array(behavior.validate())
	if rank < 1:
		errors.append("rank must be positive")
	if damage_type not in ["PHYSICAL", "MAGIC", "TRUE"]:
		errors.append("unknown damage type")
	for field: StringName in [&"cooldown", &"damage", &"range_px", &"radius_px", &"duration", &"projectile_speed", &"shield"]:
		var value: float = get(field)
		if not is_finite(value) or value < 0.0:
			errors.append("rank %d: %s must be finite and nonnegative" % [rank, field])
	if projectile_count < 1 or pierce_count < 0:
		errors.append("invalid projectile/pierce count")
	return errors
