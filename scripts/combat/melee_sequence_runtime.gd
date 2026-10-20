class_name MeleeSequenceRuntime
extends Node2D
var intent: CastIntent
var combat: CombatService
var definition: MeleeSequenceExecutor
var elapsed: float=0
var ticks: int=0
var burns: int=0
var resolved: bool=false
var retargets: int=0
var finished: bool=false
var center: Vector2
var tick_hits: Dictionary[String,bool]={}
func _ready() -> void:
	center=intent.aim_point
	var owner: Actor=intent.source()
	if definition.move in ["rush","chain","nuke"]:
		owner.set_meta("movement_lock_runtime",weakref(self));owner.velocity=Vector2.ZERO
	if definition.move=="rush":owner.motion_active=true
	if definition.move=="nuke":owner.invulnerability_left=maxf(owner.invulnerability_left,definition.windup)
	_visual("melee_warning",center if definition.move=="debris" else owner.global_position,combat.modified_radius(intent),definition.windup)
func _physics_process(delta: float) -> void:
	var owner: Actor=intent.source()
	if not is_instance_valid(owner) or not owner.health.is_alive():_finish(false);return
	if owner.statuses.stunned():
		if definition.move=="nuke" and not resolved and intent.runtime!=null:intent.runtime.refund_base_fraction(.5)
		if definition.move!="debris" or not resolved:_finish(false);return
	elapsed+=delta
	if elapsed<definition.windup:return
	match definition.move:
		"rush":_rush(owner,delta)
		"chain":_chain(owner)
		"debris":_debris(owner)
		"nuke":_nuke(owner)
func _rush(owner: Actor,delta: float) -> void:
	var count: int=definition.base_hits+(definition.rank2_extra_hits if intent.rank.rank>=2 else 0)
	var duration: float=count*definition.hit_interval
	var collided: bool=owner.move_and_collide(intent.direction*intent.rank.range_px*minf(delta,maxf(0,definition.windup+duration-elapsed+delta))/duration)!=null
	while ticks<count and elapsed>=definition.windup+ticks*definition.hit_interval:
		_strike(owner,intent.rank.damage,ticks==count-1,ticks);ticks+=1
	if collided or elapsed>=definition.windup+duration:_finish(true)
func _chain(owner: Actor) -> void:
	var count: int=4+(1 if intent.rank.rank>=2 else 0)
	while ticks<count and elapsed>=definition.windup+ticks*definition.hit_interval:
		var target: Actor=intent.target()
		if intent.rank.rank>=4 and (not is_instance_valid(target) or not target.health.is_alive()) and retargets<definition.retarget_limit:
			target=TargetingService.nearest(owner,combat.actors(),intent.rank.range_px)
			if target!=null:intent.target_ref=weakref(target);intent.direction=owner.global_position.direction_to(target.global_position);retargets+=1
		if ticks>0:
			var travel: float=definition.step_distance
			if is_instance_valid(target) and target.health.is_alive():travel=clampf((target.global_position-owner.global_position).dot(intent.direction)-35,0,travel)
			owner.move_and_collide(intent.direction*travel)
		var values: Array[float]=[50,50,50,100,60]
		var scale: float=intent.rank.damage/50.0
		_strike(owner,values[ticks]*scale,ticks==count-1,ticks);ticks+=1
	if elapsed>=definition.windup+count*definition.hit_interval:_finish(true)
func _strike(owner: Actor,damage: float,last: bool,index: int) -> void:
	if not intent.context.budget.spend_proc(intent.context.generation_depth+1):return
	var rank:=intent.rank.duplicate(true) as SkillRankDefinition;rank.damage=damage
	for target in combat.actors():
		var offset: Vector2=target.global_position-owner.global_position
		if target.team==owner.team or offset.length()>rank.radius_px or absf(intent.direction.angle_to(offset))>deg_to_rad(definition.arc_degrees*.5) or not combat.unobstructed(owner.global_position,target.global_position):continue
		var key: String="%d:%d"%[index,target.actor_id]
		if tick_hits.has(key):continue
		tick_hits[key]=true
		var context: CombatContext=intent.context.event_copy()
		context.can_trigger_on_hit=last;context.can_trigger_on_kill=false
		var result: DamageResult=combat.hit(owner,target,rank,context)
		if not result.accepted or not last:continue
		if definition.move=="rush" and intent.rank.rank>=3 and not target.is_boss:_status(target,"stun",.5)
		if definition.move=="rush" and intent.rank.rank>=4:target.marked_by=owner.actor_id;target.mark_bonus=.12;target.mark_left=3
		if definition.move=="chain" and intent.rank.rank>=3:_status(target,"slow",2,.15 if target.is_boss else .3)
		if not target.is_boss:
			var push: Vector2=intent.direction*(28 if definition.move=="chain" or intent.rank.rank>=3 else 12)
			if not target.test_move(target.global_transform,push):target.global_position+=push
	_visual("melee_strike",combat.cast_origin(owner),rank.radius_px,.16)
func _debris(owner: Actor) -> void:
	if not resolved:
		resolved=true
		var rank:=intent.rank.duplicate(true) as SkillRankDefinition
		for target in combat.actors():
			if target.team!=owner.team and target.global_position.distance_to(center)<=combat.modified_radius(intent) and combat.unobstructed(center,target.global_position):
				combat.hit(owner,target,rank,intent.context)
				if not target.is_boss:_status(target,"stun",1 if rank.rank>=4 else .2)
		_visual("melee_slam",center,combat.modified_radius(intent),.3)
		if intent.context.is_echo:_finish(true);return
		_visual("melee_field",center,combat.modified_radius(intent),definition.field_lifetime)
		_echo()
	while ticks<int(definition.field_lifetime/definition.field_tick) and elapsed>=definition.windup+(ticks+1)*definition.field_tick:
		ticks+=1;_field_hit(owner,definition.field_damage,"debris")
	if intent.rank.rank>=3:
		while burns<int(definition.burn_duration/definition.field_tick) and elapsed>=definition.windup+(burns+1)*definition.field_tick:
			burns+=1;_field_hit(owner,definition.burn_damage,"burn")
	if elapsed>=definition.windup+definition.field_lifetime:_finish(true)
func _field_hit(owner: Actor,damage: float,operation: String) -> void:
	var context: CombatContext=intent.context.child(StringName(operation))
	if context==null:return
	context.can_trigger_on_hit=false;context.can_trigger_on_kill=false
	var rank:=intent.rank.duplicate(true) as SkillRankDefinition;rank.damage=damage;rank.behavior=null
	# An empty behavior disables criticals for ground ticks in the shared resolver.
	rank.behavior=SkillBehaviorDefinition.new()
	for target in combat.actors():
		if target.team!=owner.team and target.global_position.distance_to(center)<=combat.modified_radius(intent) and combat.unobstructed(center,target.global_position):combat.hit(owner,target,rank,context)
func _nuke(owner: Actor) -> void:
	if resolved:return
	resolved=true
	var target: Actor=intent.target()
	if is_instance_valid(target) and target.health.is_alive() and target.team!=owner.team and owner.global_position.distance_to(target.global_position)<=intent.rank.range_px and combat.unobstructed(owner.global_position,target.global_position):
		combat.hit(owner,target,intent.rank,intent.context)
		if not target.is_boss:_status(target,"stun",.5)
		_visual("melee_nuke",target.hit_position(),70,.4)
	if intent.rank.rank>=3:
		var fear_count: int=0
		for other in combat.actors():
			if other is EnemyActor and not other.is_boss and other.team!=owner.team and owner.global_position.distance_to(other.global_position)<=120:
				var old: WeakRef=other.get_meta("fear_motion") as WeakRef if other.has_meta("fear_motion") else null
				if old!=null and is_instance_valid(old.get_ref()) and not (old.get_ref() as Node).is_queued_for_deletion():
					(old.get_ref() as MeleeFear).remaining=1
					continue
				var fear:=MeleeFear.new();fear.victim_ref=weakref(other);fear.away_from=owner.global_position;combat.add_child(fear)
				fear_count+=1
				if fear_count>=32:break
	_finish(true)
func _status(target: Actor,kind: String,duration: float,strength: float=0) -> void:
	var effect:=StatusEffectDefinition.new();effect.kind=kind;effect.duration=duration;effect.strength=strength;target.statuses.apply(effect,target.is_boss)
func _echo() -> void:
	combat.queue_echo(definition,intent,MeleeSequenceExecutor.replay.bind(combat,definition))
func _visual(kind: String,point: Vector2,radius: float,duration: float) -> void:
	combat.visual_event.emit({"kind":kind,"skill":intent.context.source_skill_id,"position":point,"radius":radius,"duration":duration,"direction":intent.direction,"runtime":weakref(self)})
func _finish(completed: bool) -> void:
	if finished:return
	finished=true
	if completed and definition.move in ["rush","chain"]:
		combat.dash_completed(intent);_echo()
	queue_free()
func _exit_tree() -> void:
	var owner: Actor=intent.source() if intent!=null else null
	if not is_instance_valid(owner):return
	var lock: WeakRef=owner.get_meta("movement_lock_runtime") as WeakRef if owner.has_meta("movement_lock_runtime") else null
	if lock!=null and lock.get_ref()==self:owner.remove_meta("movement_lock_runtime")
	if definition.move=="rush":owner.motion_active=false;owner.velocity=Vector2.ZERO
