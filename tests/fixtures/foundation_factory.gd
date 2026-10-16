class_name FoundationFactory
extends RefCounted
## Schema-only fixtures. They do not claim that skill executors exist.

static func skill(slot: int = 0) -> SkillDefinition:
	var value := SkillDefinition.new()
	value.id = StringName("skill.fixture.%d" % slot)
	value.display_name = "Fixture skill %d" % slot
	value.slot = slot
	value.unlock_level = [1, 3, 6, 9, 11][slot]
	value.max_rank = [1, 4, 4, 4, 3][slot]
	value.executor = SkillExecutorDefinition.new()
	value.executor.executor_id = &"executor.fixture_schema_only"
	value.targeting = TargetingDefinition.new()
	for index in range(value.max_rank):
		var entry := SkillRankDefinition.new()
		entry.rank = index + 1
		entry.cooldown = 7.0
		entry.damage = 36.0
		value.rank_scaling.append(entry)
	return value

static func character() -> CharacterDefinition:
	var value := CharacterDefinition.new()
	value.id = &"character.fixture"
	value.display_name = "Schema fixture, not playable"
	value.class_id = &"mage"
	value.base_stats = ActorStatDefinition.new()
	value.basic_attack = skill(0)
	for slot in range(1, 5):
		value.active_skills.append(skill(slot))
	return value

static func augment() -> AugmentDefinition:
	var value := AugmentDefinition.new()
	value.id = &"augment.fixture"
	value.display_name = "Schema fixture"
	value.requirements = RequirementDefinition.new()
	var effect := AugmentEffectDefinition.new()
	effect.effect_id = &"effect.fixture_schema_only"
	effect.rank_values = [1.0, 2.0, 3.0, 4.0, 5.0]
	value.effects.append(effect)
	return value

static func enemy() -> EnemyDefinition:
	var value := EnemyDefinition.new()
	value.id = &"enemy.fixture"
	value.display_name = "Fixture enemy"
	value.stats = ActorStatDefinition.new()
	return value

static func boss() -> BossDefinition:
	var value := BossDefinition.new()
	value.id = &"boss.fixture"
	value.display_name = "Fixture boss"
	value.actor = enemy()
	return value
