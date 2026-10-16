class_name MapDefinition
extends ContentDefinition

@export var bounds: Rect2 = Rect2(-1100, -750, 2200, 1500)
@export var safe_spawn_anchor: Vector2 = Vector2.ZERO
@export var safe_spawn_radius: float = 250.0
@export var enemy_exclusion_radius: float = 550.0
@export var spawn_attempts: int = 30
@export var min_path_width: float = 80.0
@export var obstacle_count: int = 8
@export var ground_color: Color = Color("111d2a")
@export var obstacle_color: Color = Color("34475b")
@export var hazards: Array[Rect2] = []
@export var hazard_damage: float = 5
@export var hazard_interval: float = .5

func validate() -> PackedStringArray:
	var errors := super.validate()
	for hazard in hazards:
		if not hazard.position.is_finite() or not hazard.size.is_finite() or not bounds.encloses(hazard) or hazard.grow(safe_spawn_radius).has_point(safe_spawn_anchor): errors.append("%s: unsafe hazard geometry" % id)
	if not is_finite(hazard_damage) or hazard_damage < 0 or not is_finite(hazard_interval) or hazard_interval <= 0: errors.append("%s: invalid hazard timing/damage" % id)
	if not bounds.position.is_finite() or not bounds.size.is_finite() or bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		errors.append("%s: map bounds must be finite and positive" % id)
	if not safe_spawn_anchor.is_finite() or not bounds.has_point(safe_spawn_anchor):
		errors.append("%s: safe anchor outside bounds" % id)
	if not is_finite(safe_spawn_radius) or safe_spawn_radius < 250.0 or not is_finite(enemy_exclusion_radius) or enemy_exclusion_radius < 550.0 or spawn_attempts < 1 or not is_finite(min_path_width) or min_path_width <= 0.0:
		errors.append("%s: invalid spawn safety/path bounds" % id)
	return errors
