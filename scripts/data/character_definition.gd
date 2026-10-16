class_name CharacterDefinition
extends ContentDefinition

@export var class_id: StringName
@export var base_stats: ActorStatDefinition
@export var basic_attack: SkillDefinition
@export var active_skills: Array[SkillDefinition] = []

func validate() -> PackedStringArray:
	var errors := super.validate()
	if class_id not in [&"mage", &"adc", &"brute"]:
		errors.append("%s: class must be mage/adc/brute" % id)
	if base_stats == null:
		errors.append("%s: base_stats reference is required" % id)
	else:
		errors.append_array(base_stats.validate())
	if basic_attack == null or basic_attack.slot != 0:
		errors.append("%s: basic attack must have slot 0" % id)
	if active_skills.size() != 4:
		errors.append("%s: exactly four active skills required" % id)
	for index in range(active_skills.size()):
		if active_skills[index] == null or active_skills[index].slot != index + 1:
			errors.append("%s: missing or invalid skill slot %d" % [id, index + 1])
	return errors

func references() -> Array[Resource]:
	var result := super.references()
	result.append(basic_attack)
	for skill in active_skills:
		result.append(skill)
	return result
