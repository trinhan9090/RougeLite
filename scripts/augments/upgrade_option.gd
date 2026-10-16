class_name UpgradeOption
extends RefCounted
var definition: AugmentDefinition
var target_skill_id: StringName
var target_skill_name: String
var slot: int = 0
var is_skill_rank: bool = false
var current_rank: int = 0
var id: StringName:
	get: return target_skill_id if is_skill_rank else definition.id

func key() -> String:
	return "rank:%s" % target_skill_id if is_skill_rank else "%s:%s" % [definition.id, target_skill_id]

func weight() -> float:
	return 25.0 if is_skill_rank else definition.rarity_weight

func label() -> String:
	var target: String = target_skill_name if not target_skill_name.is_empty() else String(target_skill_id)
	if is_skill_rank: return "Skill rank %d -> %d\n%s" % [current_rank, current_rank + 1, target]
	var text: String = "%s\n%s\n%s | Rank %d -> %d" % [definition.display_name, definition.description, target if target_skill_id != &"" else "Global", current_rank, current_rank + 1]
	for effect in definition.effects:
		if effect is MechanicEffectDefinition:
			text += "\nWas: %s\nNext: %s" % [(effect as MechanicEffectDefinition).describe_rank(current_rank), (effect as MechanicEffectDefinition).describe_rank(current_rank + 1)]
	return text
