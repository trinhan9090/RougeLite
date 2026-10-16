extends SceneTree

var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", label)
	else:
		_failures += 1
		printerr("FAIL ", label)

func _run() -> void:
	var registry := root.get_node("ContentRegistry") as ContentRegistryService
	var cores: Array[AugmentDefinition] = []
	for id in registry.content_ids():
		if String(id).begins_with("stat."):
			cores.append(registry.definition_copy(id) as AugmentDefinition)
	_check(cores.size() == 8, "eight registered stat cores")
	for profile_id: String in ["astra", "boros"]:
		var profile := load("res://content/characters/%s_loadout.tres" % profile_id) as CombatLoadoutDefinition
		var actor := Actor.new()
		actor.stats_definition = profile.stats
		root.add_child(actor)
		var manager := AugmentManager.new()
		actor.health.commit_resolved_hp(actor.health.maximum / 2.0)
		for core in cores:
			_check(manager.apply(core, actor), "shared stat modifier applies %s/%s" % [profile_id, core.id])
		_check(is_equal_approx(actor.health.current / actor.health.maximum, 0.5), "max HP preserves damage ratio %s" % profile_id)
		var state := RunState.new(81)
		var progression := LevelManager.new(state, load("res://content/progression/default.tres") as ProgressionDefinition)
		var valid: bool = true
		for level in range(1, 121):
			progression.add_xp(progression.curve.threshold(state.current_level))
			var offers := OfferGenerator.generate(cores, manager, state.rng.stream(&"offers"))
			valid = valid and offers.size() == 3
			if offers.size() != 3:
				break
			valid = valid and offers[0].id != offers[1].id and offers[0].id != offers[2].id and offers[1].id != offers[2].id
			valid = valid and manager.apply(offers[0], actor)
			progression.acknowledge_choice()
		_check(valid and state.current_level == 121, "120 sequential levels keep three distinct eligible options %s" % profile_id)
		for index in range(100):
			for core in cores:
				manager.apply(core, actor)
		_check(actor.stats.move_speed <= 550.0 and actor.stats.crit_chance <= 1.0 and actor.stats.cooldown_reduction <= 0.6, "effective stat caps %s" % profile_id)
		_check(manager.rank_for(&"stat.damage") > 100, "stat ranks remain repeatable %s" % profile_id)
		_check(is_equal_approx(profile.stats.max_hp, 130.0 if profile_id == "astra" else 260.0), "stat upgrade does not mutate content %s" % profile_id)
		var incompatible := cores[0].duplicate(true) as AugmentDefinition
		incompatible.scope = "SKILL_TARGETED"
		_check(not manager.apply(incompatible, actor), "global stat refuses incompatible target scope %s" % profile_id)
		actor.health.commit_resolved_hp(0)
		_check(not manager.apply(cores[0], actor), "dead actor cannot upgrade %s" % profile_id)
		actor.queue_free()
		await process_frame
	var first := AugmentManager.new()
	var second := AugmentManager.new()
	var left := OfferGenerator.generate(cores, first, RunRng.new(42).stream(&"offers"))
	var right := OfferGenerator.generate(cores, second, RunRng.new(42).stream(&"offers"))
	_check(left[0].id == right[0].id and left[1].id == right[1].id and left[2].id == right[2].id, "same seed/state produces same three cards")
	_check(OfferGenerator.generate([cores[0], cores[0]], first, RunRng.new(1).stream(&"offers")).is_empty(), "duplicate/insufficient candidate pool fails closed")
	var capped := FoundationFactory.augment()
	capped.max_rank = 6
	_check(not capped.validate().is_empty(), "passive cap validation regression")
	print("RESULT upgrades: checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
