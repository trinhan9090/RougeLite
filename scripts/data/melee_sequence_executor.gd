class_name MeleeSequenceExecutor
extends EffectExecutorDefinition
## Reusable bounded melee patterns composed with the existing combat/context services.
@export_enum("rush","debris","chain","nuke") var move: String="rush"
@export var windup: float=.08
@export var hit_interval: float=.1
@export var base_hits: int=6
@export var rank2_extra_hits: int=2
@export var step_distance: float=40
@export var arc_degrees: float=110
@export var field_lifetime: float=6
@export var field_tick: float=.5
@export var field_damage: float=7
@export var burn_duration: float=3
@export var burn_damage: float=8
@export var retarget_limit: int=2
@export var field_cap: int=3
func supported_capabilities() -> Array[StringName]:
	var caps: Array[StringName]=[&"damage",&"cooldown_manage",&"apply_status"]
	if move=="debris":caps.append(&"on_kill_hook")
	else:caps.append(&"on_hit_hook")
	if move!="nuke":caps.append(&"repeat_cast")
	if move=="debris":caps.append(&"resize_area")
	if move in ["rush","chain"]:caps.append(&"dash_completed_hook")
	return caps
func validate() -> PackedStringArray:
	var errors:=super.validate()
	if move not in ["rush","debris","chain","nuke"] or base_hits<1 or base_hits>12 or rank2_extra_hits<0 or base_hits+rank2_extra_hits>16 or field_cap<1 or field_cap>4 or retarget_limit<0 or retarget_limit>2:errors.append("invalid melee sequence bounds")
	for value in [windup,hit_interval,step_distance,arc_degrees,field_lifetime,field_tick,field_damage,burn_duration,burn_damage]:
		if not is_finite(value) or value<0:errors.append("invalid melee sequence number")
	if hit_interval<=0 or field_tick<.5 or field_lifetime>6 or burn_duration>3 or arc_degrees>360:errors.append("invalid sequence timing/geometry")
	return errors
func execute_cast(intent: CastIntent,combat: CombatService) -> bool:
	var owner: Actor=intent.source()
	if not is_instance_valid(owner) or not owner.health.is_alive() or owner.motion_active:return false
	var lock: WeakRef=owner.get_meta("movement_lock_runtime") as WeakRef if owner.has_meta("movement_lock_runtime") else null
	if lock!=null and is_instance_valid(lock.get_ref()) and not (lock.get_ref() as Node).is_queued_for_deletion():return false
	if move=="nuke":
		var target: Actor=intent.target()
		if not is_instance_valid(target) or owner.global_position.distance_to(target.global_position)>intent.rank.range_px:return false
		if intent.manual and absf(intent.direction.angle_to(target.global_position-owner.global_position))>deg_to_rad(arc_degrees*.5):return false
		if not combat.unobstructed(owner.global_position,target.global_position):return false
	if move=="debris" and not intent.context.is_echo:
		var fields: Array[Node]=[]
		for node in combat.get_children():
			if node is MeleeSequenceRuntime and node.definition.move=="debris" and node.intent.source()==owner and not node.is_queued_for_deletion():fields.append(node)
		if fields.size()>=field_cap:fields[0].queue_free()
	intent.context.freeze_modifiers()
	var effect:=MeleeSequenceRuntime.new();effect.intent=intent;effect.definition=self;effect.combat=combat;combat.add_child(effect)
	return true

static func replay(copy: CastIntent,service: CombatService,configuration: MeleeSequenceExecutor) -> void:
	configuration.execute_cast(copy,service)
