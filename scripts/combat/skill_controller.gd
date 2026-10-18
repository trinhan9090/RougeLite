class_name SkillController
extends RefCounted
## Both Auto and Manual submit the same validated cast command.

signal skill_unlocked(slot: int, skill_id: StringName)
var _slots: Dictionary[int, SkillRuntime] = {}
var _errors := PackedStringArray()
var _owner: WeakRef
var _combat: WeakRef
var _mode: StringName = &"AUTO"
var candidates: Array[Actor] = []
var augments: AugmentManager
signal skill_cast(slot: int, context: CombatContext)

func _init(actor_id: int, definitions: Array[SkillDefinition], basic: SkillDefinition = null) -> void:
	if definitions.size() != 4 or actor_id <= 0:
		_errors.append("SkillController requires an owner and exactly four active definitions")
		return
	var candidate: Dictionary[int, SkillRuntime] = {}
	var seen_ids: Dictionary[StringName, bool] = {}
	for index in range(4):
		var definition: SkillDefinition = definitions[index]
		if definition == null:
			_errors.append("Missing active definition at slot %d" % (index + 1))
			continue
		_errors.append_array(definition.validate())
		if definition.slot != index + 1 or seen_ids.has(definition.id):
			_errors.append("Active slots must be ordered 1..4 with unique skill IDs")
		seen_ids[definition.id] = true
		candidate[index + 1] = SkillRuntime.new(definition, actor_id)
	if _errors.is_empty():
		_slots = candidate
		if basic != null:
			var basic_runtime := SkillRuntime.new(basic, actor_id)
			if basic_runtime.valid():
				basic_runtime.unlock_for_level(1)
				_slots[0] = basic_runtime

func configuration_errors() -> PackedStringArray:
	return _errors.duplicate()

func runtime_for(slot: int) -> SkillRuntime:
	return _slots.get(slot)

func sync_level(level: int) -> Array[int]:
	var unlocked: Array[int] = []
	if not _errors.is_empty():
		return unlocked
	for slot in range(1, 5):
		var runtime: SkillRuntime = _slots[slot]
		if runtime.unlock_for_level(level):
			unlocked.append(slot)
			skill_unlocked.emit(slot, runtime.definition.id)
	return unlocked

func upgrade_rank(slot: int) -> bool:
	var runtime: SkillRuntime = runtime_for(slot)
	return runtime != null and runtime.upgrade_rank()

func advance_cooldowns(delta: float, simulation_active: bool = true) -> void:
	for runtime: SkillRuntime in _slots.values():
		runtime.advance_cooldown(delta, simulation_active)

func bind(owner: Actor, combat: CombatService) -> void:
	_owner = weakref(owner)
	_combat = weakref(combat)
	for runtime: SkillRuntime in _slots.values(): runtime.bind_owner(owner)

func accepts_upgrades() -> bool:
	if not _errors.is_empty(): return false
	if _owner == null: return true
	var owner: Actor = _owner.get_ref() as Actor
	return is_instance_valid(owner) and not owner.is_queued_for_deletion() and owner.health.is_alive()

func set_mode(value: StringName) -> bool:
	if value not in [&"AUTO", &"MANUAL"]:
		return false
	_mode = value
	return true

func mode() -> StringName:
	return _mode

func auto_step() -> int:
	if _mode != &"AUTO":
		return 0
	var count: int = 0
	for slot in range(1, 5):
		if request_cast(slot):
			count += 1
	return count

func request_cast(slot: int, target_override: Variant = null) -> bool:
	if slot < 1 or slot > 4: return false
	var runtime: SkillRuntime = runtime_for(slot)
	var owner: Actor = _owner.get_ref() as Actor if _owner != null else null
	var combat: CombatService = _combat.get_ref() as CombatService if _combat != null else null
	if runtime == null or not runtime.cooldown_ready() or not is_instance_valid(owner) or not is_instance_valid(combat) or not owner.health.is_alive() or owner.statuses.stunned() or not combat.simulation_active():
		return false
	if owner.actor_id != runtime.owner_actor_id: return false
	var definition: SkillDefinition = runtime.definition
	var rank: SkillRankDefinition = runtime.effective_rank()
	var range_px: float = definition.targeting.acquisition_radius if definition.targeting.acquisition_radius > 0 else rank.range_px
	var adapter := definition.executor as EffectExecutorDefinition
	if adapter != null and adapter.kind in ["projectile","dash","beam","area"]:
		if rank.range_px > 0: range_px = rank.range_px
		elif adapter.kind == "area": range_px = rank.radius_px * (1.0 + (augments.value(definition.id,&"area") if augments != null else 0.0))
	var target: Actor = TargetingService.nearest(owner, candidates, range_px)
	var manual: bool = target_override is Vector2
	var assisted: bool = definition.targeting.prefer_nearest_with_facing_fallback
	if definition.targeting.policy == "self":
		if not manual and (target == null or (adapter != null and adapter.kind == "shield" and owner.health.shield_total() > 0.0)):
			return false
	elif target == null and not manual and not assisted:
		return false
	var aim: Vector2 = target.global_position if target != null else owner.global_position + Vector2.RIGHT * rank.range_px
	if manual and not (assisted and target != null):
		aim = target_override
		if owner is PlayerActor:
			var player := owner as PlayerActor
			aim = player.global_position + player.attack_direction * maxf(1,rank.range_px)
	if assisted and target == null and owner is PlayerActor:
		var player := owner as PlayerActor
		aim = owner.global_position + (player.attack_direction if manual else player.facing) * maxf(1,rank.range_px)
	var offset: Vector2 = aim - owner.global_position
	var intent := CastIntent.new()
	intent.source_ref = weakref(owner)
	if target != null:
		intent.target_ref = weakref(target)
	intent.runtime = runtime
	intent.rank = rank
	intent.aim_point = owner.global_position + offset.limit_length(rank.range_px) if rank.range_px > 0 else owner.global_position
	intent.direction = offset.normalized() if offset.length_squared() > 0 else Vector2.RIGHT
	if not manual and adapter != null and adapter.kind in ["projectile","beam"]:
		intent.direction = combat.cast_origin(owner).direction_to(target.hit_position() if target!=null else aim)
	intent.manual = manual
	intent.context = combat.next_context(owner, definition.id)
	intent.context.manager = augments
	intent.context.runtime = runtime
	if not definition.executor.execute_cast(intent, combat):
		return false
	if owner is PlayerActor and definition.targeting.policy != "self":
		(owner as PlayerActor).record_attack_direction(intent.direction)
	runtime.commit_cast(owner.stats.cooldown_reduction)
	skill_cast.emit(slot, intent.context)
	return true
