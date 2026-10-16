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
	var skill := SkillRuntime.new(load("res://content/skills/astra_j.tres") as SkillDefinition, 1)
	skill.unlock_for_level(3)
	var manager := AugmentManager.new()
	var definition := load("res://content/augments/mechanics/explosion_on_hit.tres") as AugmentDefinition
	manager.apply_bound(definition, skill)
	var context := CombatContext.new()
	context.root_cast_id = 12
	context.event_id = 12000000
	context.source_skill_id = skill.definition.id
	context.manager = manager
	check(context.value(&"explosion") == 15, "cast captures rank1 modifier")
	manager.apply_bound(definition, skill)
	check(context.value(&"explosion") == 15 and manager.value(skill.definition.id, &"explosion") == 20, "in-flight cast snapshot survives later upgrade")
	var collision_a: CombatContext = context.event_copy(1)
	var collision_b: CombatContext = context.event_copy(2)
	check(collision_a.event_id != collision_b.event_id and collision_a.parent_event_id == context.event_id and collision_a.projectile_id == 1 and collision_b.projectile_id == 2, "collision envelope unique event/projectile IDs and parent")
	var retained: int = collision_a.event_id
	context.event_copy(3)
	check(collision_a.event_id == retained, "published event envelope remains stable")
	var secondary: CombatContext = context.child(&"fixture")
	check(context.proc_budget_remaining == 31 and secondary.proc_budget_remaining == 31, "envelopes report live shared remaining budget")
	check(context.allows(&"explosion") and not secondary.allows(&"explosion"), "PRIMARY_ONLY filters secondary")
	var once := definition.duplicate(true) as AugmentDefinition
	once.effects[0].trigger_policy = "ONCE_PER_ROOT_CAST"
	var once_manager := AugmentManager.new()
	once_manager.apply_bound(once, skill)
	var once_context := CombatContext.new()
	once_context.source_skill_id = skill.definition.id
	once_context.manager = once_manager
	check(once_context.allows(&"explosion") and not once_context.allows(&"explosion") and not once_context.child(&"fixture").allows(&"explosion"), "ONCE_PER_ROOT_CAST dedupes sibling contexts")
	var allowed := definition.duplicate(true) as AugmentDefinition
	allowed.effects[0].trigger_policy = "ALLOW_SECONDARY"
	var allowed_manager := AugmentManager.new()
	allowed_manager.apply_bound(allowed, skill)
	var allowed_context := CombatContext.new()
	allowed_context.source_skill_id = skill.definition.id
	allowed_context.manager = allowed_manager
	var chain: CombatContext = allowed_context
	for depth in range(3):
		chain = chain.child(&"explosion")
		check(chain != null and chain.allows(&"explosion"), "ALLOW_SECONDARY bounded depth%d" % (depth + 1))
	check(chain.child(&"explosion") == null, "ALLOW_SECONDARY cannot exceed shared depth")
	var forged := definition.duplicate(true) as AugmentDefinition
	forged.requirements.required_capabilities.clear()
	check(not forged.validate().is_empty() and not manager.can_bind(forged, skill), "missing mechanic capability requirements fail closed")
	var bad_skill := skill.definition
	bad_skill.rank_scaling[0].projectile_speed = 0
	check(not bad_skill.validate().is_empty(), "projectile capability requires executable geometry")
	var limits := CombatLimitsDefinition.new()
	limits.chain_depth = 1
	limits.secondary_procs = 2
	limits.projectiles_per_root = 3
	var budget := CastBudget.new()
	budget.configure(limits)
	check(budget.spend_proc(1) and not budget.spend_proc(2) and budget.spend_proc(1) and not budget.spend_proc(1), "combat limits are data configurable")
	check(budget.spend_projectile() and budget.spend_projectile() and budget.spend_projectile() and not budget.spend_projectile(), "configured projectile limit enforced")
	limits.projectiles_per_root = 0
	check(not limits.validate().is_empty(), "invalid combat limits rejected")
	print("RESULT event envelope: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
