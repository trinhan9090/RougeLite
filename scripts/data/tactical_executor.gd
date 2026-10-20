class_name TacticalExecutor
extends EffectExecutorDefinition
## Generic bounded ordnance adapter; shared projectile, damage and augment services own resolution.
@export_enum("burst","grenade","mines","rocket") var move: String = "burst"
@export var firing_socket: Vector2=Vector2(32,-38)
@export var windup: float = 0.0
@export var shot_interval: float = .08
@export var spread_degrees: float = 22
@export var hit_cap: int = 5
@export var mine_cap: int = 6
@export var mine_arm: float = .5
@export var mine_lifetime: float = 12
@export var mine_trigger: float = 42
@export var chain_radius: float = 120
@export var mine_boss_scale: float = .7
@export var knockback: float = 16

func supported_capabilities() -> Array[StringName]:
	var caps: Array[StringName]=[&"damage",&"on_hit_hook",&"on_kill_hook",&"cooldown_manage",&"repeat_cast"]
	if move=="burst":caps.append_array([&"modify_projectile_angle",&"spawn_projectile_pattern",&"modify_projectile_count",&"pierce_hit",&"projectile_steering"])
	else:caps.append(&"resize_area")
	if move=="mines":caps.append(&"apply_status")
	return caps

func validate() -> PackedStringArray:
	var errors:=super.validate()
	if not firing_socket.is_finite():errors.append("invalid tactical firing socket")
	if move not in ["burst","grenade","mines","rocket"]:errors.append("invalid tactical adapter")
	for number in [windup,shot_interval,spread_degrees,mine_arm,mine_lifetime,mine_trigger,chain_radius,mine_boss_scale,knockback]:
		if not is_finite(number) or number<0:errors.append("invalid tactical timing/geometry")
	if hit_cap<1 or mine_cap<1 or shot_interval<=0 or mine_lifetime<=mine_arm:errors.append("invalid tactical budget")
	return errors

func execute_cast(intent: CastIntent,combat: CombatService) -> bool:
	if not is_instance_valid(intent.source()) or not intent.source().health.is_alive():return false
	intent.context.freeze_modifiers()
	if not intent.manual and not intent.context.is_echo and move=="rocket":
		var best: Actor
		var best_score: int=-1
		for target in combat.actors():
			if target.team==intent.source().team or target.global_position.distance_to(intent.source().global_position)>intent.rank.range_px or not combat.unobstructed(intent.source().global_position,target.global_position):continue
			var score: int=10000 if move=="rocket" and target.is_boss else 0
			for neighbor in combat.actors():
				if neighbor.team!=target.team or neighbor.global_position.distance_to(target.global_position)>combat.modified_radius(intent):continue
				score+=1
			if score>best_score:best_score=score;best=target
		if best!=null:
			intent.aim_point=best.global_position;intent.direction=combat.cast_origin(intent.source()).direction_to(best.hit_position());intent.target_ref=weakref(best)
	if intent.source() is PlayerActor:
		var owner: Actor=intent.source()
		var side: float=signf(intent.direction.x)
		if side==0:side=signf(owner.cast_origin_offset.x)
		if side==0:side=1
		owner.cast_origin_offset=Vector2(firing_socket.x*side,firing_socket.y)
		if not intent.manual and move in ["burst","rocket"] and is_instance_valid(intent.target()):intent.direction=combat.cast_origin(owner).direction_to(intent.target().hit_position())
	var runtime:=TacticalRuntime.new()
	runtime.intent=intent;runtime.definition=self;runtime.combat=combat
	combat.add_child(runtime)
	combat.queue_echo(self,intent,func(copy: CastIntent) -> void: execute_cast(copy,combat))
	return true
