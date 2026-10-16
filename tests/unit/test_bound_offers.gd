extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS ", label)
	else:
		failures += 1
		printerr("FAIL ", label)
func run_tests() -> void:
	var registry := root.get_node("ContentRegistry") as ContentRegistryService
	var definitions: Array[AugmentDefinition] = []
	for id in registry.content_ids():
		var definition := registry.definition_copy(id) as AugmentDefinition
		if definition != null: definitions.append(definition)
	var descriptions_valid: bool = true
	for definition in definitions:
		for effect in definition.effects:
			if effect is MechanicEffectDefinition:
				for rank in range(1, definition.max_rank + 1): descriptions_valid = descriptions_valid and not (effect as MechanicEffectDefinition).describe_rank(rank).is_empty()
	check(descriptions_valid, "all mechanic rank tooltips format numeric values")
	var split := registry.definition_copy(&"augment.projectile_split") as AugmentDefinition
	check((split.effects[0] as MechanicEffectDefinition).describe_rank(5) == "6 extra shots, 65% damage", "Split rank5 tooltip shows confirmed numbers")
	for identity in ["astra", "vex", "boros"]:
		var profile := load("res://content/characters/%s_loadout.tres" % identity) as CombatLoadoutDefinition
		var controller := SkillController.new(1, profile.active_skills)
		var manager := AugmentManager.new()
		var stream: RandomNumberGenerator = RunRng.new(50).stream(&"offers")
		var locked: Array[UpgradeOption] = OfferGenerator.generate_bound(definitions, manager, controller, stream)
		check(locked.size() == 3 and locked.all(func(option: UpgradeOption) -> bool: return not option.is_skill_rank and option.target_skill_id == &""), "%s locked slots only offer stats" % identity)
		controller.sync_level(11)
		var valid: bool = true
		for trial in range(200):
			var cards: Array[UpgradeOption] = OfferGenerator.generate_bound(definitions, manager, controller, stream)
			var seen: Dictionary[String, bool] = {}
			valid = valid and cards.size() == 3
			for card in cards:
				valid = valid and not seen.has(card.key())
				seen[card.key()] = true
				if card.is_skill_rank: valid = valid and controller.runtime_for(card.slot).rank < controller.runtime_for(card.slot).definition.max_rank
				elif card.target_skill_id != &"": valid = valid and manager.can_bind(card.definition, controller.runtime_for(card.slot))
				else: valid = valid and manager.can_apply(card.definition)
		check(valid, "%s 200 seeded offers contain3 distinct valid bound options" % identity)
		for slot in range(1, 5):
			var runtime: SkillRuntime = controller.runtime_for(slot)
			while runtime.upgrade_rank(): pass
			for definition in definitions:
				while manager.apply_bound(definition, runtime): pass
		var capped: Array[UpgradeOption] = OfferGenerator.generate_bound(definitions, manager, controller, stream)
		check(capped.size() == 3 and capped.all(func(option: UpgradeOption) -> bool: return not option.is_skill_rank and option.target_skill_id == &""), "%s all mechanic/skill caps fall back to3 infinite stats" % identity)
		var seed_a: RandomNumberGenerator = RunRng.new(70).stream(&"offers")
		var seed_b: RandomNumberGenerator = RunRng.new(70).stream(&"offers")
		var a: Array[UpgradeOption] = OfferGenerator.generate_bound(definitions, manager, controller, seed_a)
		var b: Array[UpgradeOption] = OfferGenerator.generate_bound(definitions, manager, controller, seed_b)
		check(a[0].key() == b[0].key() and a[1].key() == b[1].key() and a[2].key() == b[2].key(), "%s offers deterministic" % identity)
	# Exact level3 ordering: new unlocked rank and mechanic options visible to generator.
	var profile := load("res://content/characters/astra_loadout.tres") as CombatLoadoutDefinition
	var controller := SkillController.new(1, profile.active_skills)
	var state := RunState.new(13, "test")
	state.current_level = 2
	var progression := LevelManager.new(state, ProgressionDefinition.new())
	progression.level_entered.connect(controller.sync_level)
	var observed: Array[bool] = []
	progression.level_applied.connect(func(_level: int) -> void: observed.append(controller.runtime_for(1).rank == 1 and AugmentManager.new().can_bind(load("res://content/augments/mechanics/projectile_split.tres") as AugmentDefinition, controller.runtime_for(1))))
	progression.add_xp(progression.curve.threshold(2))
	check(observed == [true], "unlock precedes same-level rank and mechanic eligibility")
	print("RESULT bound offers: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
