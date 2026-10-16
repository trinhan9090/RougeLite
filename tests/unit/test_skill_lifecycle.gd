extends SceneTree

var _checks: int = 0
var _failures: int = 0
var _offer_count: int = 0
var _offer_order_valid: bool = true

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
	var definitions: Array[SkillDefinition] = FoundationFactory.character().active_skills
	var controller := SkillController.new(1, definitions)
	_check(controller.configuration_errors().is_empty(), "four ordered active definitions accepted")
	_check(controller.sync_level(1).is_empty(), "all actives locked at level 1")
	_check(not controller.upgrade_rank(1) and not controller.runtime_for(1).commit_cast(), "locked skill cannot rank up or commit cast")
	var milestones: Array[int] = [3, 6, 9, 11]
	for slot in range(1, 5):
		_check(controller.sync_level(milestones[slot - 1] - 1).is_empty(), "slot %d locked before exact milestone" % slot)
		_check(controller.sync_level(milestones[slot - 1]) == [slot] and controller.runtime_for(slot).rank == 1, "free rank 1 at exact milestone %d" % milestones[slot - 1])
		_check(controller.sync_level(milestones[slot - 1]).is_empty(), "milestone %d idempotent" % milestones[slot - 1])
		var maximum: int = 3 if slot == 4 else 4
		for next_rank in range(2, maximum + 1):
			_check(controller.upgrade_rank(slot) and controller.runtime_for(slot).rank == next_rank, "slot %d paid rank %d" % [slot, next_rank])
		_check(not controller.upgrade_rank(slot) and controller.runtime_for(slot).rank == maximum, "slot %d rank cap enforced" % slot)
	var runtime: SkillRuntime = controller.runtime_for(1)
	_check(runtime.commit_cast(0.2) and is_equal_approx(runtime.cooldown_remaining, 5.6), "cooldown uses current rank and CDR")
	_check(not runtime.commit_cast() and runtime.cast_sequence_number == 1, "cooldown rejects duplicate commit")
	controller.advance_cooldowns(2.0, false)
	_check(is_equal_approx(runtime.cooldown_remaining, 5.6), "paused simulation does not advance cooldown")
	controller.advance_cooldowns(2.0)
	_check(is_equal_approx(runtime.cooldown_remaining, 3.6), "simulation delta advances cooldown")
	runtime.advance_cooldown(-1)
	runtime.advance_cooldown(NAN)
	_check(is_equal_approx(runtime.cooldown_remaining, 3.6), "invalid delta ignored")
	runtime.advance_cooldown(100)
	_check(runtime.cooldown_ready() and runtime.cooldown_remaining == 0.0, "cooldown clamps at zero")
	_check(runtime.commit_cast(99) and is_equal_approx(runtime.cooldown_remaining, 2.8), "CDR capped at 60 percent")
	var other := SkillController.new(2, definitions)
	other.sync_level(11)
	_check(other.runtime_for(1).rank == 1 and other.runtime_for(1).cooldown_remaining == 0, "rank and cooldown isolated across owners")
	var snapshot: SkillDefinition = runtime.definition
	snapshot.rank_scaling[0].cooldown = 999
	definitions[0].rank_scaling[0].cooldown = 888
	_check(runtime.definition.rank_scaling[0].cooldown == 7.0, "source and returned Resource mutations isolated")
	var jump := SkillController.new(3, FoundationFactory.character().active_skills)
	_check(jump.sync_level(99) == [1, 2, 3, 4], "large level jump unlocks all missed milestones once")
	_check(not jump.runtime_for(1).has_capability(&"spawn_projectile_pattern"), "schema fixture cannot advertise unimplemented capability")
	var invalid := SkillController.new(4, [])
	_check(not invalid.configuration_errors().is_empty() and invalid.runtime_for(1) == null, "invalid slot configuration fails closed")
	var broken: Array[SkillDefinition] = FoundationFactory.character().active_skills
	broken[0].max_rank = 9
	invalid = SkillController.new(4, broken)
	_check(not invalid.configuration_errors().is_empty() and invalid.sync_level(99).is_empty(), "invalid rank definition cannot unlock partially")
	var state := RunState.new(12)
	var queued := SkillController.new(5, FoundationFactory.character().active_skills)
	var progression := LevelManager.new(state, load("res://content/progression/default.tres") as ProgressionDefinition)
	progression.level_entered.connect(queued.sync_level)
	progression.level_applied.connect(func(level: int) -> void:
		_offer_count += 1
		for slot in range(1, 5):
			if level >= milestones[slot - 1] and queued.runtime_for(slot).rank != 1:
				_offer_order_valid = false
	)
	var xp: int = 0
	for level in range(1, 11):
		xp += progression.curve.threshold(level)
	progression.add_xp(xp)
	while progression.awaiting_choice:
		progression.acknowledge_choice()
	_check(state.current_level == 11 and _offer_count == 10 and _offer_order_valid, "batched XP unlock phase precedes every normal level offer")
	print("RESULT skill lifecycle: checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
