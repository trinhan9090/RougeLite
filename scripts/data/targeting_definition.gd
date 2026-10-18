class_name TargetingDefinition
extends Resource

@export_enum("nearest", "cursor", "self", "movement") var policy: String = "nearest"
@export var acquisition_radius: float = 0.0
@export var prefer_nearest_with_facing_fallback: bool = false

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if policy not in ["nearest", "cursor", "self", "movement"]:
		errors.append("unknown targeting policy")
	if not is_finite(acquisition_radius) or acquisition_radius < 0.0:
		errors.append("acquisition_radius must be finite and nonnegative")
	return errors
