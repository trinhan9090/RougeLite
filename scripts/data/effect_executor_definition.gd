class_name EffectExecutorDefinition
extends SkillExecutorDefinition
## Capability declarations derive from real adapters, never tags or character IDs.
@export_enum("projectile", "area", "beam", "shield", "dash", "status", "buff") var kind: String = "projectile"
@export var status: StatusEffectDefinition
@export var tick_interval: float = 0.5
@export var spread_radians: float = 0.12
@export var dash_duration: float = 0.28

func validate() -> PackedStringArray:
	var errors := super.validate()
	if kind not in ["projectile", "area", "beam", "shield", "dash", "status", "buff"]: errors.append("unknown effect adapter")
	if not is_finite(tick_interval) or tick_interval <= 0 or not is_finite(dash_duration) or dash_duration <= 0 or not is_finite(spread_radians) or spread_radians < 0: errors.append("invalid effect timing/geometry")
	if kind == "status" and status == null: errors.append("status adapter requires status")
	if status != null: errors.append_array(status.validate())
	return errors

func supported_capabilities() -> Array[StringName]:
	var caps: Array[StringName] = []
	if kind in ["projectile", "area", "beam", "dash"]: caps.append_array([&"damage", &"on_hit_hook", &"on_kill_hook", &"cooldown_manage"])
	if kind in ["projectile", "area", "beam"]: caps.append(&"repeat_cast")
	if kind == "projectile": caps.append_array([&"modify_projectile_angle", &"spawn_projectile_pattern", &"modify_projectile_count", &"pierce_hit", &"projectile_steering"])
	if kind in ["area", "beam"]: caps.append(&"resize_area")
	if kind == "shield": caps.append_array([&"modify_shield", &"damage_taken_hook"])
	if kind == "dash": caps.append(&"dash_completed_hook")
	if status != null: caps.append(&"apply_status")
	return caps

func execute_cast(intent: CastIntent, combat: CombatService) -> bool:
	return combat.execute_effect(self, intent)
