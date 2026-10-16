class_name CombatLoadoutDefinition
extends ContentDefinition
## M1 basic-only projection. Full CharacterDefinition with 4 actives is M3.

@export var character_id: StringName
@export var class_id: StringName
@export var stats: ActorStatDefinition
@export var basic_attack: SkillDefinition
@export var active_skills: Array[SkillDefinition] = []
@export var tint: Color = Color("71d8f3")
@export var visual_frames: SpriteFrames
@export var art_frames: SpriteFrames
@export_enum("staff","pistols","hammer") var weapon: String = "staff"

func validate() -> PackedStringArray:
	var errors := super.validate()
	if character_id == &"" or class_id not in [&"mage", &"adc", &"brute"]:
		errors.append("%s: invalid character/class identity" % id)
	if stats == null:
		errors.append("%s: stats reference required" % id)
	else:
		errors.append_array(stats.validate())
	if basic_attack == null or basic_attack.slot != 0:
		errors.append("%s: basic slot reference required" % id)
	if not active_skills.is_empty():
		var controller := SkillController.new(1, active_skills)
		errors.append_array(controller.configuration_errors())
	return errors

func references() -> Array[Resource]:
	var result := super.references()
	result.append(basic_attack)
	for skill in active_skills: result.append(skill)
	return result
