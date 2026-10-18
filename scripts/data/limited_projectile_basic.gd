class_name LimitedProjectileBasic
extends BasicAttackExecutorDefinition
## Separate acquisition radius from travel distance without copying projectile logic.
@export var travel_distance: float = 340
func execute(combat: CombatService,source: Actor,target: Actor,rank: SkillRankDefinition,context: CombatContext) -> bool:
	if not combat.unobstructed(combat.cast_origin(source),target.hit_position()):return false
	var shot := rank.duplicate(true) as SkillRankDefinition
	shot.range_px=travel_distance
	return super.execute(combat,source,target,shot,context)
