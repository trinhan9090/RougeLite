class_name CastIntent
extends RefCounted
## Ephemeral validated geometry; event envelopes contain IDs, never Node refs.

var source_ref: WeakRef
var target_ref: WeakRef
var runtime: SkillRuntime
var rank: SkillRankDefinition
var context: CombatContext
var aim_point: Vector2
var direction: Vector2 = Vector2.RIGHT
var manual: bool = false

func source() -> Actor:
	return source_ref.get_ref() as Actor if source_ref != null else null

func target() -> Actor:
	return target_ref.get_ref() as Actor if target_ref != null else null
