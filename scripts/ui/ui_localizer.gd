class_name UiLocalizer
extends RefCounted
## Translate presentation copies; stable IDs and content definitions stay intact.
static func upgrade_label(option: UpgradeOption) -> String:
	var text: String = option.label()
	if option.definition != null:
		text = text.replace(option.definition.display_name,TranslationServer.translate(option.definition.display_name))
		text = text.replace(option.definition.description,TranslationServer.translate(option.definition.description))
	if not option.target_skill_name.is_empty():
		text = text.replace(option.target_skill_name,TranslationServer.translate(option.target_skill_name))
	for term: String in ["damage echo after","of absorbed damage","turning strength","primary shots","targets pierced","extra shots","physical damage","magic damage","Skill rank","chance; refund","Global","Rank","Was:","Next:","None","radius","damage","below","CD"]:
		text = text.replace(term,TranslationServer.translate(term))
	return text
