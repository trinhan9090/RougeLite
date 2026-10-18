class_name RankEffectSystem
extends RefCounted
var combat: CombatService
var clock: float = 0
var shields: Array[Dictionary] = []
var traps: Dictionary[int, Dictionary] = {}

func advance(delta: float) -> void:
	clock += delta
	for entry in shields.duplicate():
		entry.left -= delta
		var actor: Actor = entry.owner.get_ref() as Actor
		if not is_instance_valid(actor) or not actor.health.is_alive():
			shields.erase(entry)
			continue
		if entry.left <= 0:
			entry.shield.duration_left = 0
			var behavior: SkillBehaviorDefinition = entry.behavior
			if behavior.expire_damage > 0: combat.queue_burst(actor, actor.global_position, entry.context, &"shield_expire", behavior.expire_damage, behavior.expire_radius)
			if behavior.expire_heal_fraction > 0: actor.health.commit_resolved_hp(actor.health.current + minf(behavior.expire_heal_cap, entry.shield.absorbed * behavior.expire_heal_fraction))
			shields.erase(entry)
	for id: int in traps.keys():
		if traps[id].until <= clock: traps.erase(id)

func cast_started(intent: CastIntent, kind: String) -> void:
	var behavior: SkillBehaviorDefinition = intent.rank.behavior
	if behavior == null: return
	var actor: Actor = intent.source()
	if behavior.move_bonus > 0 or behavior.attack_bonus > 0:
		actor.add_buff(intent.context.source_skill_id, behavior.buff_duration, {&"move_speed": behavior.move_bonus, &"attack_speed": behavior.attack_bonus})
		combat.visual_event.emit({"kind":"buff","skill":intent.context.source_skill_id,"position":actor.global_position,"follow":weakref(actor),"buff_id":intent.context.source_skill_id,"duration":behavior.buff_duration})
	if kind == "buff":
		actor.add_buff(intent.context.source_skill_id, intent.rank.duration, {&"max_hp": behavior.hp_bonus, &"range": behavior.range_bonus})
		actor.native_pulse_scale = behavior.basic_pulse_scale
		actor.native_pulse_radius = behavior.basic_pulse_radius
	if kind == "shield":
		actor.add_buff(StringName("shield:" + String(intent.context.source_skill_id)), intent.rank.duration, {&"damage_taken": -behavior.shield_reduction})
		var shield: ShieldInstance = actor.health.shields.back()
		shield.context = intent.context
		shield.behavior = behavior
		shields.append({"owner": weakref(actor), "left": intent.rank.duration, "shield": shield, "context": intent.context, "behavior": behavior})
	if kind == "dash":
		actor.extra_basic = behavior.extra_basic
		actor.kill_refund_runtime = intent.runtime
		actor.kill_refund_seconds = behavior.kill_refund
		actor.kill_refund_left = behavior.buff_duration

func hit_resolved(source: Actor, target: Actor, rank: SkillRankDefinition, context: CombatContext, result: DamageResult) -> void:
	var behavior: SkillBehaviorDefinition = rank.behavior
	if result.killed and source.kill_refund_left > 0 and source.kill_refund_runtime != null:
		source.kill_refund_runtime.advance_cooldown(source.kill_refund_seconds)
		source.kill_refund_left = 0
	if behavior == null: return
	if target.health.is_alive() and behavior.mark_duration > 0:
		target.marked_by = source.actor_id
		target.mark_bonus = behavior.mark_bonus
		target.mark_left = behavior.mark_duration
	if target.health.is_alive() and behavior.death_damage > 0:
		traps[target.actor_id] = {"owner":weakref(source),"context":context,"behavior":behavior,"until":clock + behavior.status.duration}
		if not target.died.is_connected(_trap_died): target.died.connect(_trap_died)
	if behavior.bounce_chance > 0 and not context.is_secondary and combat.rng.randf() < behavior.bounce_chance:
		var candidates: Array[Actor] = combat.actors().filter(func(actor: Actor) -> bool: return actor != target and actor.team != source.team)
		var next: Actor = TargetingService.nearest(source,candidates,rank.range_px)
		var child: CombatContext = context.child(&"bounce") if next != null else null
		if child != null:
			var copy := rank.duplicate(true) as SkillRankDefinition
			copy.damage *= behavior.bounce_scale
			copy.behavior = null
			var source_ref: WeakRef = weakref(source)
			var next_ref: WeakRef = weakref(next)
			var bounce_origin:Vector2=target.hit_position()
			combat.schedule(0,func() -> void:
				var a: Actor = source_ref.get_ref() as Actor
				var b: Actor = next_ref.get_ref() as Actor
				if is_instance_valid(a) and is_instance_valid(b):
					var hit:DamageResult=combat.hit(a,b,copy,child)
					if hit.accepted:combat.visual_event.emit({"kind":"ricochet","skill":child.source_skill_id,"position":bounce_origin,"line_end":b.hit_position()-bounce_origin,"radius":2.0,"duration":.12}))

func _trap_died(target: Actor) -> void:
	if not traps.has(target.actor_id): return
	var entry: Dictionary = traps[target.actor_id]
	traps.erase(target.actor_id)
	var source: Actor = entry.owner.get_ref() as Actor
	if is_instance_valid(source): combat.queue_burst(source,target.global_position,entry.context,&"trapped_death",entry.behavior.death_damage,entry.behavior.death_radius)

func blocked(source: Actor, target: Actor, incoming: CombatContext, result: DamageResult) -> void:
	if incoming.source_augment_id in [&"reflect", &"native_reflect"]: return
	for shield in target.health.shields:
		if shield.behavior == null or shield.duration_left <= 0 or result.shield_damage <= 0: continue
		var behavior: SkillBehaviorDefinition = shield.behavior
		if behavior.blocked_pulse > 0 and shield.pulse_left <= 0:
			shield.pulse_left = behavior.blocked_interval
			combat.queue_burst(target,target.global_position,shield.context,&"blocked_pulse",behavior.blocked_pulse,110)
		if behavior.reflect_fraction > 0:
			var context: CombatContext = incoming.child(&"native_reflect")
			if context == null: continue
			context.owner_actor_id = target.actor_id
			context.source_skill_id = shield.context.source_skill_id
			var rank := SkillRankDefinition.new()
			rank.damage = result.mitigated_damage * behavior.reflect_fraction
			rank.damage_type = "TRUE"
			var a: WeakRef = weakref(source)
			var b: WeakRef = weakref(target)
			combat.schedule(0,func() -> void:
				if is_instance_valid(a.get_ref()) and is_instance_valid(b.get_ref()): combat.hit(b.get_ref() as Actor,a.get_ref() as Actor,rank,context))
