class_name AugmentDefinition
extends ContentDefinition

@export var max_rank: int = 5 # 0 means infinite stat core
@export_multiline var description: String = ""
@export_enum("GLOBAL", "CLASS_WEIGHTED", "SKILL_TARGETED", "SIGNATURE") var scope: String = "SKILL_TARGETED"
@export var requirements: RequirementDefinition
@export var effects: Array[AugmentEffectDefinition] = []
@export var rarity_weight: float = 55.0

func validate() -> PackedStringArray:
	var errors := super.validate()
	var is_stat: bool = String(id).begins_with("stat.")
	if scope not in ["GLOBAL", "CLASS_WEIGHTED", "SKILL_TARGETED", "SIGNATURE"]:
		errors.append("%s: invalid scope" % id)
	if (is_stat and (max_rank != 0 or scope != "GLOBAL")) or (not is_stat and scope != "SIGNATURE" and max_rank not in [4, 5]) or (scope == "SIGNATURE" and max_rank != 1):
		errors.append("%s: invalid rank cap or stat scope" % id)
	if not is_finite(rarity_weight) or rarity_weight <= 0.0:
		errors.append("%s: rarity_weight must be finite and positive" % id)
	if requirements == null:
		errors.append("%s: requirements reference is required" % id)
	elif scope == "SIGNATURE" and requirements.required_character_id == &"":
		errors.append("%s: signature requires explicit character ID" % id)
	if effects.is_empty():
		errors.append("%s: at least one effect required" % id)
	for effect in effects:
		if effect == null:
			errors.append("%s: empty effect reference" % id)
		else:
			errors.append_array(effect.validate(1 if is_stat else max_rank))
			if effect is MechanicEffectDefinition and requirements != null:
				for capability in (effect as MechanicEffectDefinition).required_capabilities():
					if not requirements.required_capabilities.has(capability): errors.append("%s: mechanic missing requirement %s" % [id, capability])
	return errors
