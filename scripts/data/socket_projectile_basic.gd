class_name SocketProjectileBasic
extends BasicAttackExecutorDefinition
## Optional data-defined source-art muzzle socket; delegates all real projectile logic.
@export var firing_socket: Vector2=Vector2(32,-46)
func execute(combat: CombatService,source: Actor,target: Actor,rank: SkillRankDefinition,context: CombatContext) -> bool:
	if source is PlayerActor and is_instance_valid(target):
		var side: float=signf(target.hit_position().x-source.global_position.x)
		if side==0:side=signf(source.cast_origin_offset.x)
		if side==0:side=1
		source.cast_origin_offset=Vector2(firing_socket.x*side,firing_socket.y)
	return super.execute(combat,source,target,rank,context)
func validate() -> PackedStringArray:
	var errors:=super.validate()
	if not firing_socket.is_finite():errors.append("invalid firing socket")
	return errors
