class_name CombatService
extends Node2D
signal visual_event(event: Dictionary)
signal projectile_fired(source: Actor, skill_id: StringName)
## Per-run service, no autoload state. Basic projectiles snapshot rank at spawn.

var rng: RandomNumberGenerator
var resolver: DamageResolver = DamageResolver.new()
var max_projectiles: int = 300
var _cast_sequence: int = 0
var actor_provider: Callable
var _queue: Array[Dictionary] = []
var _shields: Dictionary[int, CombatContext] = {}
var event_count: int = 0
var limits: CombatLimitsDefinition = preload("res://content/progression/combat_limits.tres")
var rank_effects: RankEffectSystem

func _ready() -> void:
	rank_effects = RankEffectSystem.new()
	rank_effects.combat = self
	if not limits.validate().is_empty():
		push_error("Combat limits invalid: %s" % limits.validate())
		get_tree().quit(1)

func _physics_process(delta: float) -> void:
	rank_effects.advance(delta)
	# Drain a snapshot: newly scheduled procs execute on a later frame, never recursively.
	var pending: Array[Dictionary] = _queue
	_queue = []
	for task in pending:
		task.delay -= delta
		if task.delay > 0: _queue.append(task)
		else: task.action.call()

func schedule(delay: float, action: Callable) -> void:
	_queue.append({"delay": delay, "action": action})

func clear_transients() -> void:
	_queue.clear()
	_shields.clear()
	rank_effects = RankEffectSystem.new()
	rank_effects.combat = self
	for child in get_children(): child.queue_free()

func actors() -> Array[Actor]:
	var result: Array[Actor] = []
	if not actor_provider.is_valid(): return result
	for raw in actor_provider.call():
		if is_instance_valid(raw) and raw is Actor and raw.health.is_alive(): result.append(raw)
	result.sort_custom(func(a: Actor, b: Actor) -> bool: return a.actor_id < b.actor_id)
	return result

func modifier(context: CombatContext, operation: StringName, auxiliary: bool = false) -> float:
	return context.value(operation, auxiliary)

func simulation_active() -> bool:
	return is_inside_tree() and not get_tree().paused

func cast_origin(source: Actor) -> Vector2:
	var origin: Vector2 = source.global_position + source.cast_origin_offset
	if source.cast_origin_offset == Vector2.ZERO: return origin
	var query := PhysicsRayQueryParameters2D.create(source.global_position,origin,4)
	query.hit_from_inside = true
	var collision: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not collision.is_empty():
		return collision.position + (source.global_position-origin).normalized()
	return origin

func next_context(source: Actor, skill_id: StringName) -> CombatContext:
	_cast_sequence += 1
	var context := CombatContext.new()
	context.budget.configure(limits)
	context.root_cast_id = _cast_sequence
	context.event_id = _cast_sequence * 1000000
	context.owner_actor_id = source.actor_id
	context.source_skill_id = skill_id
	return context

func spawn_projectile(source: Actor, target: Actor, rank: SkillRankDefinition, context: CombatContext) -> bool:
	if get_child_count() >= max_projectiles or rank.projectile_speed <= 0.0 or not context.budget.spend_projectile():
		return false
	var projectile := CombatProjectile.new()
	projectile.configure(self, source, target, rank, context)
	add_child(projectile)
	projectile.global_position = cast_origin(source)
	projectile_fired.emit(source,context.source_skill_id)
	return true

func hit(source: Actor, target: Actor, rank: SkillRankDefinition, parent_context: CombatContext, projectile_id: int = 0, status: StatusEffectDefinition = null) -> DamageResult:
	if not is_instance_valid(source) or not is_instance_valid(target): return DamageResult.new()
	var context: CombatContext = parent_context.event_copy(projectile_id)
	event_count += 1
	var packet := DamagePacket.new()
	packet.base_damage = rank.damage
	var behavior: SkillBehaviorDefinition = rank.behavior
	if behavior != null:
		var hp_bonus: float = source.health.maximum * behavior.max_hp_damage
		if target.is_boss: hp_bonus = minf(hp_bonus, behavior.max_hp_boss_cap)
		packet.base_damage += hp_bonus
		if target.is_boss: packet.base_damage *= 1.0 + behavior.boss_bonus
	if target.health.current < target.health.maximum * 0.25:
		packet.base_damage *= 1.0 + modifier(context, &"execute")
	packet.damage_type = StringName(rank.damage_type)
	packet.can_crit = behavior.can_crit if behavior != null else true
	packet.crit_bonus = behavior.crit_bonus if behavior != null else 0.0
	if context.source_augment_id in [&"reflect",&"native_reflect"]:
		packet.can_crit = false
		packet.scale_with_stats = false
	packet.context = context
	packet.status = behavior.status if behavior != null and behavior.status != null else status
	var result: DamageResult = resolver.resolve(packet, source, target, rng)
	if result.accepted:
		if target.team!=1 and result.mitigated_damage>0:
			visual_event.emit({"kind":"damage_number","position":target.hit_position(),"height":90 if target.is_boss else 48,"amount":result.mitigated_damage,"critical":result.critical,"follow":weakref(target)})
		visual_event.emit({"kind":"impact","skill":context.source_skill_id,"position":target.hit_position(),"radius":14})
		if packet.status != null and target.statuses.movement_factor()==0:
			visual_event.emit({"kind":"status","skill":context.source_skill_id,"position":target.global_position,"radius":21,
				"duration":packet.status.duration,"follow":weakref(target),"target_id":target.actor_id})
		if result.shield_damage > 0:
			var guard_skill:StringName=context.source_skill_id
			if _shields.has(target.actor_id):guard_skill=(_shields[target.actor_id] as CombatContext).source_skill_id
			visual_event.emit({"kind":"guard_hit","skill":guard_skill,"position":target.global_position,"follow":weakref(target),"radius":18,"duration":.14})
		queue_hit_procs(source, target, context, result)
		queue_reflect(source, target, context, result)
		rank_effects.hit_resolved(source,target,rank,context,result)
		rank_effects.blocked(source,target,context,result)
	return result

func beam_receivers(source: Actor, origin: Vector2, direction: Vector2, length: float, radius: float) -> Array[Actor]:
	var box := RectangleShape2D.new()
	box.size=Vector2(maxf(.01,length),maxf(.01,radius*2))
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape=box
	query.transform=Transform2D(direction.angle(),origin+direction*length*.5)
	query.collision_mask=2|16 if source.team==1 else 1|8
	query.collide_with_areas=true
	var intersected: Dictionary[int,bool]={}
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query,512):
		var receiver: Object=result.collider
		var actor: Actor=receiver.actor if receiver is ActorHurtbox else receiver as Actor
		if actor!=null and (receiver is ActorHurtbox or not is_instance_valid(actor.hurtbox)):intersected[actor.actor_id]=true
	var targets: Array[Actor]=[]
	for target in actors():
		if target.team==source.team:continue
		var offset: Vector2=target.hit_position()-origin
		var inside: bool=intersected.has(target.actor_id) if is_instance_valid(target.hurtbox) else (offset.dot(direction)>=0 and offset.dot(direction)<=length and absf(offset.cross(direction))<=radius)
		if inside and unobstructed(origin,target.hit_position()) and unobstructed(origin,target.global_position):targets.append(target)
	return targets

func execute_effect(executor: EffectExecutorDefinition, intent: CastIntent) -> bool:
	var source: Actor = intent.source()
	if not is_instance_valid(source) or not source.health.is_alive(): return false
	intent.context.freeze_modifiers()
	if executor.kind == "projectile":
		if not spawn_pattern(executor, intent): return false
	elif executor.kind == "shield":
		if intent.rank.shield <= 0: return false
		source.health.shields.append(ShieldInstance.new(intent.rank.shield, intent.rank.duration))
		_shields[source.actor_id] = intent.context
	elif executor.kind in ["area", "dash"]:
		if executor.kind == "dash" and (source.motion_active or source.statuses.movement_factor() == 0 or source.test_move(source.global_transform, intent.direction * intent.rank.range_px)): return false
		var effect := TimedCombatEffect.new()
		effect.combat = self
		effect.intent = intent
		effect.executor = executor
		add_child(effect)
	elif executor.kind == "beam":
		var origin: Vector2 = cast_origin(source)
		var flash := CombatFlash.new()
		flash.line_end = intent.direction * intent.rank.range_px
		flash.radius = modified_radius(intent)
		add_child(flash)
		flash.global_position = origin
		var ids: Dictionary[int, bool] = {}
		for target in beam_receivers(source,origin,intent.direction,intent.rank.range_px,modified_radius(intent)):
			deliver(intent, target, executor.status, ids)
	elif executor.kind == "status":
		var target: Actor = intent.target()
		if target == null or not target.health.is_alive(): return false
		target.statuses.apply(executor.status, target.is_boss)
	elif executor.kind == "buff":
		if intent.rank.behavior == null: return false
	else: return false
	rank_effects.cast_started(intent,executor.kind)
	if executor.kind in ["shield","buff","beam"]:
		var presentation: Dictionary = {"kind":executor.kind,"skill":intent.context.source_skill_id,"position":source.global_position,
			"radius":modified_radius(intent) if executor.kind == "beam" else 28.0,
			"duration":.35,"line_end":intent.direction*intent.rank.range_px if executor.kind == "beam" else Vector2.ZERO}
		if executor.kind == "beam": presentation["position"] = cast_origin(source)
		if executor.kind == "buff":
			presentation["buff_id"]=intent.context.source_skill_id
			presentation["follow"]=weakref(source)
			presentation["duration"]=intent.rank.duration
		if executor.kind == "shield":
			presentation["shield_instance"] = source.health.shields.back()
			presentation["follow"] = weakref(source)
		visual_event.emit(presentation)
	if intent.rank.behavior != null:
		var behavior: SkillBehaviorDefinition = intent.rank.behavior
		if behavior.repeat_scale > 0 and not intent.context.is_secondary:
			var repeat := CastIntent.new()
			repeat.source_ref = intent.source_ref
			repeat.rank = intent.rank.duplicate(true) as SkillRankDefinition
			repeat.rank.damage *= behavior.repeat_scale
			repeat.rank.behavior.max_hp_damage *= behavior.repeat_scale
			repeat.rank.behavior.max_hp_boss_cap *= behavior.repeat_scale
			repeat.context = intent.context.child(&"second_ring")
			var center: Vector2 = source.global_position
			if repeat.context != null: schedule(behavior.repeat_delay,func() -> void:
				var ids: Dictionary[int,bool] = {}
				radial_hit(repeat,center,modified_radius(intent),ids))
		if behavior.burn_duration > 0:
			var burn := intent.rank.duplicate(true) as SkillRankDefinition
			burn.damage = behavior.burn_damage
			burn.radius_px=modified_radius(intent)
			burn.behavior = null
			for tick in range(1,roundi(behavior.burn_duration / .5) + 1):
				var copy := CastIntent.new()
				copy.source_ref = intent.source_ref
				copy.context = intent.context.child(&"line_burn")
				copy.rank = burn
				copy.direction = intent.direction
				copy.aim_point = cast_origin(source)
				if copy.context != null: schedule(tick * .5,func() -> void: beam_tick(copy))
	queue_echo(executor,intent,func(copy: CastIntent) -> void: execute_effect(executor,copy))
	return true

func queue_echo(executor: EffectExecutorDefinition,intent: CastIntent,replay: Callable) -> void:
	var echo_damage: float = modifier(intent.context, &"echo")
	if echo_damage > 0 and not intent.context.is_echo and intent.context.allows(&"echo") and executor.supported_capabilities().has(&"repeat_cast"):
		var child: CombatContext = intent.context.child(&"echo", true)
		if child != null:
			var echo := CastIntent.new()
			echo.source_ref = intent.source_ref
			echo.target_ref = intent.target_ref
			echo.runtime = intent.runtime
			echo.rank = intent.rank.duplicate(true) as SkillRankDefinition
			scale_rank_damage(echo.rank,echo_damage)
			echo.context = child
			echo.aim_point = intent.aim_point
			echo.direction = intent.direction
			schedule(0.6, func() -> void: replay.call(echo))

func spawn_pattern(executor: EffectExecutorDefinition, intent: CastIntent) -> bool:
	# Canonical order: base lanes -> Multishot -> Split -> damage -> pierce -> steering.
	var lanes: int = intent.rank.projectile_count + int(modifier(intent.context, &"multishot"))
	var accepted: bool = false
	for lane in range(mini(lanes, intent.context.budget.projectile_limit)):
		var angle: float = (lane - (lanes - 1) * 0.5) * executor.spread_radians
		var direction: Vector2 = intent.direction.rotated(angle)
		var delay: float = lane * intent.rank.behavior.shot_interval if intent.rank.behavior != null else 0.0
		if delay > 0:
			schedule(delay,func() -> void:
				if is_instance_valid(intent.source()) and intent.source().health.is_alive(): emit_projectile(intent,direction,1.0,executor.status))
			accepted = true
		else: accepted = emit_projectile(intent, direction, 1.0, executor.status) or accepted
		if not intent.context.is_secondary:
			var extra: int = int(modifier(intent.context, &"split"))
			var split_context: CombatContext = intent.context.child(&"split") if extra > 0 else null
			for split_index in range(extra):
				if split_context == null: break
				var side: float = -1.0 if split_index % 2 == 0 else 1.0
				var split_angle: float = side * (floorf(split_index / 2.0) + 1) * 0.13
				var split := CastIntent.new()
				split.source_ref = intent.source_ref
				split.target_ref = intent.target_ref
				split.rank = intent.rank
				split.runtime = intent.runtime
				split.context = split_context
				emit_projectile(split, direction.rotated(split_angle), modifier(intent.context, &"split", true), executor.status)
	return accepted

func emit_projectile(intent: CastIntent, direction: Vector2, scale: float, status: StatusEffectDefinition) -> bool:
	if get_child_count() >= max_projectiles or intent.rank.projectile_speed <= 0 or not intent.context.budget.spend_projectile(): return false
	var projectile := CombatProjectile.new()
	var rank := intent.rank.duplicate(true) as SkillRankDefinition
	scale_rank_damage(rank,scale)
	rank.pierce_count += int(modifier(intent.context, &"pierce"))
	projectile.configure_direction(self, intent.source(), intent.target(), rank, intent.context, direction, modifier(intent.context, &"homing") + executor_steering(intent), status)
	add_child(projectile)
	projectile.global_position = cast_origin(intent.source())
	projectile_fired.emit(intent.source(),intent.context.source_skill_id)
	return true

func scale_rank_damage(rank: SkillRankDefinition, scale: float) -> void:
	rank.damage *= scale
	if rank.behavior == null: return
	for key: StringName in [&"max_hp_damage",&"max_hp_boss_cap",&"death_damage",&"burn_damage",&"trail_damage",&"blocked_pulse",&"expire_damage"]:
		rank.behavior.set(key,float(rank.behavior.get(key))*scale)

func executor_steering(intent: CastIntent) -> float:
	# Steering is opt-in through the Homing augment, never implicit on basics.
	return 0.0

func modified_radius(intent: CastIntent) -> float:
	return intent.rank.radius_px * (1.0 + modifier(intent.context, &"area"))

func unobstructed(from: Vector2, to: Vector2) -> bool:
	return get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, 4)).is_empty()

func deliver(intent: CastIntent, target: Actor, status: StatusEffectDefinition, ids: Dictionary[int, bool]) -> void:
	if ids.has(target.actor_id): return
	ids[target.actor_id] = true
	hit(intent.source(), target, intent.rank, intent.context, 0, status)

func radial_hit(intent: CastIntent, center: Vector2, radius: float, ids: Dictionary[int, bool], status: StatusEffectDefinition = null) -> void:
	var source: Actor = intent.source()
	if not is_instance_valid(source) or not source.health.is_alive(): return
	visual_event.emit({"kind":"area","skill":intent.context.source_skill_id,"position":center,"radius":radius,"duration":.18})
	for target in actors():
		if target.team != source.team and target.global_position.distance_to(center) <= radius and unobstructed(center, target.global_position): deliver(intent, target, status, ids)

func queue_burst(source: Actor, center: Vector2, parent: CombatContext, operation: StringName, damage: float, radius: float, delay: float = 0, damage_type: String = "") -> void:
	var context: CombatContext = parent.child(operation)
	if context == null: return
	var intent := CastIntent.new()
	intent.source_ref = weakref(source)
	intent.context = context
	intent.rank = SkillRankDefinition.new()
	intent.rank.damage = damage
	intent.rank.behavior = SkillBehaviorDefinition.new() # Secondary bursts do not gain implicit skill criticals.
	intent.rank.damage_type = "PHYSICAL" if operation == &"dash_wave" else "MAGIC"
	if damage_type != "": intent.rank.damage_type = damage_type
	schedule(delay, func() -> void:
		var ids: Dictionary[int, bool] = {}
		var flash := CombatFlash.new()
		flash.radius = radius
		add_child(flash)
		flash.global_position = center
		radial_hit(intent, center, radius, ids))

func beam_tick(intent: CastIntent) -> void:
	var source: Actor = intent.source()
	if not is_instance_valid(source) or not source.health.is_alive(): return
	visual_event.emit({"kind":"burn_line","skill":intent.context.source_skill_id,"position":intent.aim_point,"line_end":intent.direction*intent.rank.range_px,"radius":intent.rank.radius_px,"duration":.5})
	var ids: Dictionary[int,bool] = {}
	for target in beam_receivers(source,intent.aim_point,intent.direction,intent.rank.range_px,intent.rank.radius_px):deliver(intent,target,null,ids)

func queue_hit_procs(source: Actor, target: Actor, context: CombatContext, result: DamageResult) -> void:
	# Policy gates are data-driven. Allowed secondary effects still spend shared budgets.
	var explosion: float = modifier(context, &"explosion")
	if explosion > 0 and context.can_trigger_on_hit and context.allows(&"explosion") and context.budget.claim("explosion:%d" % target.actor_id):
		queue_burst(source, target.global_position, context, &"explosion", explosion, modifier(context, &"explosion", true))
	var burst: float = modifier(context, &"kill_burst")
	if result.killed and not target.is_auxiliary and burst > 0 and context.can_trigger_on_kill and context.allows(&"kill_burst") and context.budget.claim("kill:%d" % target.actor_id):
		queue_burst(source, target.global_position, context, &"kill_burst", burst, 65)
	var chance: float = modifier(context, &"refund")
	if chance > 0 and context.runtime != null and context.allows(&"refund") and context.budget.claim("refund") and rng.randf() < chance:
		var child: CombatContext = context.child(&"refund")
		if child != null: schedule(0, func() -> void: context.runtime.refund_base_fraction(0.1))

func dash_completed(intent: CastIntent) -> void:
	var damage: float = modifier(intent.context, &"dash_wave")
	if damage > 0 and intent.context.budget.claim("dash_completed"):
		queue_burst(intent.source(), intent.source().global_position, intent.context, &"dash_wave", damage, 90)

func queue_reflect(source: Actor, target: Actor, incoming: CombatContext, result: DamageResult) -> void:
	if incoming.source_augment_id == &"reflect" or result.shield_damage <= 0 or not _shields.has(target.actor_id): return
	var shield_context: CombatContext = _shields[target.actor_id]
	var fraction: float = modifier(shield_context, &"reflect")
	if fraction <= 0: return
	# Reflection is a descendant of the incoming event and shares its budgets.
	var context: CombatContext = incoming.child(&"reflect")
	if context == null: return
	context.owner_actor_id = target.actor_id
	context.source_skill_id = shield_context.source_skill_id
	context.manager = shield_context.manager
	context.runtime = shield_context.runtime
	context._snapshot_ready = false
	context._modifiers.clear()
	var damage: float = result.shield_damage * fraction
	if source.is_boss: damage = minf(damage, source.health.maximum * limits.reflect_boss_hp_cap)
	var rank := SkillRankDefinition.new()
	rank.damage = damage
	rank.damage_type = "TRUE"
	var source_ref: WeakRef = weakref(source)
	var target_ref: WeakRef = weakref(target)
	schedule(0, func() -> void:
		var attacker: Actor = source_ref.get_ref() as Actor
		var defender: Actor = target_ref.get_ref() as Actor
		if is_instance_valid(attacker) and is_instance_valid(defender): hit(defender, attacker, rank, context))
