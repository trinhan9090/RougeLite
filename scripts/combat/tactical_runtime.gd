class_name TacticalRuntime
extends Node2D
var intent: CastIntent
var definition: TacticalExecutor
var combat: CombatService
var elapsed: float=0
var released: bool=false
var rounds: int=0
var hits: Dictionary[int,int]={}
var center: Vector2
var burn_ticks: int=0
var secondary_done: bool=false
var clusters: Array[Dictionary]=[]

func _ready() -> void:
	center=intent.aim_point
	if definition.move=="grenade":
		center=_safe_endpoint(combat.cast_origin(intent.source()),center)
		combat.visual_event.emit({"kind":"grenade_throw","skill":intent.context.source_skill_id,"position":combat.cast_origin(intent.source()),"endpoint":center,"duration":definition.windup,"radius":combat.modified_radius(intent)})
	elif definition.move=="rocket":combat.visual_event.emit({"kind":"rocket_warning","skill":intent.context.source_skill_id,"position":combat.cast_origin(intent.source()),"endpoint":combat.cast_origin(intent.source())+intent.direction*intent.rank.range_px,"duration":definition.windup,"radius":combat.modified_radius(intent)})
	elif definition.move=="burst":
		combat.resolver.events.damage_applied.connect(_on_damage)
		combat.child_entered_tree.connect(_guard_new_projectile)

func _safe_endpoint(origin: Vector2,point: Vector2) -> Vector2:
	var q:=PhysicsRayQueryParameters2D.create(origin,point,4)
	q.hit_from_inside=true
	var result: Dictionary=combat.get_world_2d().direct_space_state.intersect_ray(q)
	return (result.position as Vector2)+(origin-point).normalized()*3 if not result.is_empty() else point

func _physics_process(delta: float) -> void:
	var owner: Actor=intent.source()
	if not is_instance_valid(owner) or not owner.health.is_alive():queue_free();return
	elapsed+=delta
	if not released and owner.statuses.stunned():queue_free();return
	if definition.move=="burst":
		while rounds<intent.rank.projectile_count and elapsed>=definition.windup+rounds*definition.shot_interval:
			_fire_round();rounds+=1;released=true
		if elapsed>definition.windup+definition.shot_interval*intent.rank.projectile_count+intent.rank.range_px/intent.rank.projectile_speed+1:queue_free()
		return
	if not released and elapsed>=definition.windup:
		released=true
		match definition.move:
			"grenade":
				_explode(center,intent.rank.damage,combat.modified_radius(intent),"explosion",intent.context)
				if intent.rank.rank>=3:combat.visual_event.emit({"kind":"burning_ground","skill":intent.context.source_skill_id,"position":center,"radius":combat.modified_radius(intent),"duration":3.0})
			"mines":_place_mines();queue_free();return
			"rocket":_launch_rockets()
	if definition.move=="grenade" and released:
		if intent.rank.rank>=3:
			while burn_ticks<3 and elapsed>=definition.windup+burn_ticks+1:
				burn_ticks+=1
				var child: CombatContext=intent.context.child(&"burning_ground")
				if child!=null:_explode(center,16,combat.modified_radius(intent),"burn_tick",child)
		if intent.rank.rank>=4 and not secondary_done and elapsed>=definition.windup+.15:
			secondary_done=true
			for side in [-1,1]:
				var child: CombatContext=intent.context.child(&"frag_secondary")
				if child!=null:_explode(_safe_endpoint(center,center+intent.direction.orthogonal()*65*side),intent.rank.damage*.5,combat.modified_radius(intent)*.6,"explosion",child)
		if elapsed>=definition.windup+3.2:queue_free()
	elif definition.move=="rocket":
		for entry in clusters.duplicate():
			if elapsed<entry.time:continue
			clusters.erase(entry)
			var child: CombatContext=intent.context.child(&"cluster_strike")
			if child!=null:_explode(entry.point,intent.rank.damage*.4,combat.modified_radius(intent),"cluster",child,entry.index)
		if elapsed>5:queue_free()

func _fire_round() -> void:
	var shot:=CastIntent.new()
	shot.source_ref=intent.source_ref;shot.target_ref=intent.target_ref;shot.runtime=intent.runtime;shot.context=intent.context
	shot.rank=intent.rank.duplicate(true) as SkillRankDefinition
	shot.rank.projectile_count=1;shot.rank.pierce_count=1 if intent.rank.rank>=3 and rounds==0 else 0
	var offset: float=(float(rounds)/maxi(1,intent.rank.projectile_count-1)-.5)*deg_to_rad(definition.spread_degrees)
	shot.direction=intent.direction.rotated(offset)
	var pattern:=EffectExecutorDefinition.new();pattern.kind="projectile";pattern.spread_radians=.07
	combat.spawn_pattern(pattern,shot)
	combat.visual_event.emit({"kind":"fire_round","skill":intent.context.source_skill_id,"position":combat.cast_origin(intent.source()),"direction":shot.direction,"round":rounds,"radius":6,"duration":.07})

func _on_damage(context: CombatContext,result: DamageResult) -> void:
	if context.root_cast_id!=intent.context.root_cast_id or context.source_skill_id!=intent.context.source_skill_id or context.is_echo!=intent.context.is_echo or context.projectile_id==0 or result.mitigated_damage<=0:return
	hits[result.target_id]=hits.get(result.target_id,0)+1
	var target: Actor
	for candidate in combat.actors():
		if candidate.actor_id==result.target_id:target=candidate;break
	if target==null:return
	if intent.rank.rank>=4 and hits[result.target_id]>=3:
		target.marked_by=intent.source().actor_id;target.mark_bonus=.12;target.mark_left=3
	if hits[result.target_id]>=definition.hit_cap:
		for node in combat.get_children():_guard_new_projectile(node)

func _guard_new_projectile(node: Node) -> void:
	if not node is CombatProjectile:return
	var projectile:=node as CombatProjectile
	if projectile._context.root_cast_id!=intent.context.root_cast_id or projectile._context.source_skill_id!=intent.context.source_skill_id or projectile._context.is_echo!=intent.context.is_echo:return
	for target in combat.actors():
		if hits.get(target.actor_id,0)<definition.hit_cap:continue
		if not projectile._excluded.has(target.get_rid()):projectile._excluded.append(target.get_rid())
		if is_instance_valid(target.hurtbox) and not projectile._excluded.has(target.hurtbox.get_rid()):projectile._excluded.append(target.hurtbox.get_rid())

func _explode(point: Vector2,damage: float,radius: float,kind: String,context: CombatContext,tick: int=-1) -> void:
	combat.visual_event.emit({"kind":kind,"skill":intent.context.source_skill_id,"position":point,"radius":radius,"duration":.35})
	var owner: Actor=intent.source()
	for target in combat.actors():
		if target.team==owner.team or target.global_position.distance_to(point)>radius or not combat.unobstructed(point,target.global_position):continue
		if kind=="rocket_explosion":
			if not context.budget.claim("rocket_hit:%d:0"%target.actor_id) and not context.budget.claim("rocket_hit:%d:1"%target.actor_id):continue
		elif kind=="cluster" and not context.budget.claim("cluster:%d:%d"%[tick,target.actor_id]):continue
		var rank:=intent.rank.duplicate(true) as SkillRankDefinition
		rank.damage=damage;rank.behavior=SkillBehaviorDefinition.new()
		combat.hit(owner,target,rank,context)
		if definition.move=="grenade" and kind=="explosion" and not target.is_boss:
			var push: Vector2=(target.global_position-point).normalized()*definition.knockback
			if push==Vector2.ZERO:push=intent.direction*definition.knockback
			if not target.test_move(target.global_transform,push):target.global_position+=push

func _place_mines() -> void:
	var owner: Actor=intent.source()
	for index in range(intent.rank.projectile_count):
		var angle: float=deg_to_rad(-40+index*80.0/maxi(1,intent.rank.projectile_count-1))
		var point: Vector2=owner.global_position+intent.direction.rotated(angle)*70
		var shape:=CircleShape2D.new();shape.radius=12
		var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape;query.transform=Transform2D(0,point);query.collision_mask=4
		if not combat.unobstructed(owner.global_position,point) or not combat.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():continue
		var old: Array[TacticalMine]=[]
		for child in combat.get_children():
			if child is TacticalMine and not child.is_queued_for_deletion() and (child as TacticalMine).intent.source()==owner:old.append(child as TacticalMine)
		while old.size()>=definition.mine_cap:
			var first: TacticalMine=old.pop_front();first.queue_free()
		var mine:=TacticalMine.new();mine.intent=intent;mine.combat=combat;mine.definition=definition;mine.chain_leader=index==0
		mine.position=combat.to_local(point);combat.add_child(mine)

func _launch_rockets() -> void:
	for index in range(intent.rank.projectile_count):
		if combat.get_child_count()>=combat.max_projectiles or not intent.context.budget.spend_projectile():break
		var rank:=intent.rank.duplicate(true) as SkillRankDefinition;rank.damage=0;rank.behavior=SkillBehaviorDefinition.new()
		var context: CombatContext=intent.context.event_copy();context.can_trigger_on_hit=false;context.can_trigger_on_kill=false
		var projectile:=CombatProjectile.new()
		var angle: float=0 if index==0 else deg_to_rad(-12 if index==1 else 12)
		projectile.configure_direction(combat,intent.source(),intent.target(),rank,context,intent.direction.rotated(angle),0,null)
		combat.add_child(projectile);projectile.global_position=combat.cast_origin(intent.source())
		combat.projectile_fired.emit(intent.source(),intent.context.source_skill_id)
		var flight:=PayloadFlight.new();flight.projectile=projectile;flight.intent=intent;flight.combat=combat
		var main: bool=index==0
		flight.on_detonate=func(point: Vector2) -> void:
			_explode(point,intent.rank.damage*(1.0 if main else .45),combat.modified_radius(intent),"rocket_explosion",intent.context)
			if main and intent.rank.rank>=3:
				for pulse in range(3):clusters.append({"point":point,"time":elapsed+(pulse+1)*.25,"index":pulse})
		combat.add_child(flight)
		combat.visual_event.emit({"kind":"rocket_spawn","skill":intent.context.source_skill_id,"position":projectile.global_position,"direction":projectile._direction,"duration":.15,"radius":12})
