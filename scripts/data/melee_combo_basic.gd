class_name MeleeComboBasic
extends BasicAttackExecutorDefinition
## Data-configured melee combo. Sequence position belongs to the actor, never Resource.
@export var combo_damage: Array[float] = [10,15,30]
@export var arc_degrees: float = 100
func supported_capabilities() -> Array[StringName]:
	return [&"damage",&"on_hit_hook",&"on_kill_hook",&"repeat_cast"]
func validate() -> PackedStringArray:
	var errors:=super.validate()
	if strategy!="melee" or combo_damage.is_empty() or arc_degrees<=0 or arc_degrees>360:errors.append("invalid melee combo")
	for value in combo_damage:
		if not is_finite(value) or value<=0:errors.append("invalid combo damage")
	return errors
func execute(combat: CombatService,source: Actor,target: Actor,rank: SkillRankDefinition,context: CombatContext) -> bool:
	if not is_instance_valid(target) or not target.health.is_alive():return false
	var index: int=int(source.get_meta("melee_combo_index",0))%combo_damage.size()
	source.set_meta("melee_combo_index",index+1)
	var intent:=CastIntent.new()
	intent.source_ref=weakref(source);intent.target_ref=weakref(target);intent.rank=rank.duplicate(true) as SkillRankDefinition
	intent.rank.damage=combo_damage[index];intent.direction=source.global_position.direction_to(target.global_position);intent.context=context
	context.freeze_modifiers()
	_strike(combat,intent,index)
	var repeat_adapter:=EffectExecutorDefinition.new();repeat_adapter.kind="area"
	combat.queue_echo(repeat_adapter,intent,MeleeComboBasic.replay.bind(combat,self,index))
	return true
func _strike(combat: CombatService,intent: CastIntent,index: int) -> void:
	var source: Actor=intent.source()
	if not is_instance_valid(source) or not source.health.is_alive():return
	for target in combat.actors():
		var offset: Vector2=target.global_position-source.global_position
		if target.team==source.team or offset.length()>intent.rank.range_px or absf(intent.direction.angle_to(offset))>deg_to_rad(arc_degrees*.5) or not combat.unobstructed(source.global_position,target.global_position):continue
		combat.hit(source,target,intent.rank,intent.context)
	combat.visual_event.emit({"kind":"melee_combo","skill":intent.context.source_skill_id,"position":combat.cast_origin(source),"direction":intent.direction,"radius":intent.rank.range_px,"duration":.2,"combo":index})

static func replay(copy: CastIntent,service: CombatService,configuration: MeleeComboBasic,index: int) -> void:
	configuration._strike(service,copy,index)
