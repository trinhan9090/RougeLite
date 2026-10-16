class_name AttackController
extends RefCounted

signal attack_fired(target: Actor)
var definition: SkillDefinition
var cooldown_left: float = 0.0
var _owner: WeakRef
var augments: AugmentManager
var runtime: SkillRuntime
var _base_rank: SkillRankDefinition

func _init(owner: Actor, skill: SkillDefinition) -> void:
	_owner = weakref(owner)
	definition = skill
	_base_rank = skill.rank_scaling[0].duplicate(true) as SkillRankDefinition

func step(delta: float, candidates: Array[Actor], combat: CombatService) -> bool:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	var owner := _owner.get_ref() as Actor
	if not is_instance_valid(owner) or not owner.health.is_alive() or owner.statuses.stunned() or cooldown_left > 0.0:
		return false
	var range_px: float = _base_rank.range_px * owner.factor(&"range")
	var target: Actor = TargetingService.nearest(owner, candidates, range_px)
	if target == null:
		return false
	var rank := _base_rank.duplicate(true) as SkillRankDefinition
	rank.range_px = range_px
	if owner.extra_basic > 0:
		rank.projectile_count += owner.extra_basic
		owner.extra_basic = 0
	var executor := definition.executor as BasicAttackExecutorDefinition
	if executor == null:
		return false
	var context: CombatContext = combat.next_context(owner, definition.id)
	context.manager = augments
	context.runtime = runtime
	if not executor.execute(combat, owner, target, rank, context):
		return false
	cooldown_left = maxf(1.0 / 6.0, rank.cooldown / (owner.stats.attack_speed_multiplier * owner.factor(&"attack_speed")))
	if owner.native_pulse_scale > 0:
		combat.queue_burst(owner, target.global_position, context, &"basic_pulse", rank.damage * owner.native_pulse_scale, owner.native_pulse_radius,0,rank.damage_type)
	attack_fired.emit(target)
	if rank.projectile_speed <= 0:
		combat.visual_event.emit({"kind":"slash","skill":definition.id,"position":owner.global_position,"radius":range_px,"angle":owner.global_position.angle_to_point(target.global_position)})
	return true
