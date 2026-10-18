class_name TacticalMine
extends Node2D
var intent: CastIntent
var combat: CombatService
var definition: TacticalExecutor
var age: float=0
var detonated: bool=false
var chain_leader: bool=false
var armed: bool=false
func _ready() -> void:
	set_meta("tactical_mine",true)
	combat.visual_event.emit({"kind":"mine_placed","skill":intent.context.source_skill_id,"position":global_position,"runtime":weakref(self),"radius":combat.modified_radius(intent),"duration":definition.mine_lifetime})
func _physics_process(delta: float) -> void:
	if not is_instance_valid(intent.source()) or not intent.source().health.is_alive():queue_free();return
	age+=delta
	if age>=definition.mine_lifetime:queue_free();return
	if age>=definition.mine_arm and not armed:
		armed=true
		combat.visual_event.emit({"kind":"mine_armed","skill":intent.context.source_skill_id,"position":global_position,"radius":definition.mine_trigger,"duration":.15})
	if not armed or detonated:return
	for target in combat.actors():
		if target.team!=intent.source().team and target.global_position.distance_to(global_position)<=definition.mine_trigger and combat.unobstructed(global_position,target.global_position):detonate();return
func detonate(chain: bool=true) -> void:
	if detonated or not armed:return
	detonated=true
	var owner: Actor=intent.source()
	var status: StatusEffectDefinition
	if intent.rank.rank>=3:status=StatusEffectDefinition.new();status.kind="slow";status.duration=2;status.strength=.3
	combat.visual_event.emit({"kind":"mine_explosion","skill":intent.context.source_skill_id,"position":global_position,"radius":combat.modified_radius(intent),"duration":.35})
	for target in combat.actors():
		if target.team==owner.team or target.global_position.distance_to(global_position)>combat.modified_radius(intent) or not combat.unobstructed(global_position,target.global_position):continue
		var rank:=intent.rank.duplicate(true) as SkillRankDefinition
		if target.is_boss:rank.damage*=definition.mine_boss_scale
		combat.hit(owner,target,rank,intent.context,0,status)
	if chain and chain_leader and intent.rank.rank>=4:
		for node in combat.get_children():
			if node is TacticalMine and node!=self:
				var mine:=node as TacticalMine
				if mine.intent.source()==owner and mine.global_position.distance_to(global_position)<=definition.chain_radius:mine.detonate(false)
	queue_free()
