class_name SkillExecutorDefinition
extends Resource
## M0 describes identity only. M2 supplies actual executor operations/adapters.
## Unsupported declared capabilities fail closed; no fake support based on tags.

@export var executor_id: StringName

func supported_capabilities() -> Array[StringName]:
	return []

func validate() -> PackedStringArray:
	return PackedStringArray(["executor_id required"]) if executor_id == &"" else PackedStringArray()

func execute_cast(_intent: CastIntent, _combat: CombatService) -> bool:
	# Unsupported authoring-only executor: fail closed, never consumes cooldown.
	return false
