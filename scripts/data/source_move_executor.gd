class_name SourceMoveExecutor
extends EffectExecutorDefinition
## Bounded content adapter using existing damage, status and context contracts.
@export_enum("cone", "control", "companion", "charged_beam") var move: String = "cone"
@export var windup: float = .12
@export var arc_degrees: float = 85

func supported_capabilities() -> Array[StringName]:
	if move == "cone": return [&"damage", &"on_hit_hook", &"on_kill_hook", &"cooldown_manage", &"resize_area"]
	if move == "control": return [&"apply_status", &"cooldown_manage"]
	if move == "charged_beam": return [&"damage", &"on_hit_hook", &"on_kill_hook", &"cooldown_manage", &"resize_area"]
	return [&"damage", &"on_hit_hook", &"on_kill_hook", &"cooldown_manage"]

func validate() -> PackedStringArray:
	var errors := super.validate()
	if move not in ["cone","control","companion","charged_beam"] or windup < 0 or not is_finite(windup) or arc_degrees <= 0 or arc_degrees > 360: errors.append("invalid source move")
	return errors

func execute_cast(intent: CastIntent, combat: CombatService) -> bool:
	var owner: Actor = intent.source()
	if not is_instance_valid(owner) or not owner.health.is_alive(): return false
	if move == "companion":
		var old: WeakRef = owner.get_meta("companion_runtime") as WeakRef if owner.has_meta("companion_runtime") else null
		if old != null and is_instance_valid(old.get_ref()): return false
	if move == "control" and not is_instance_valid(intent.target()): return false
	if move == "control" and intent.manual:
		var chosen: Actor
		var distance: float = intent.rank.range_px+1
		for target in combat.actors():
			var offset: Vector2 = target.global_position-owner.global_position
			if target.team != owner.team and offset.length() <= intent.rank.range_px and offset.length() < distance and absf(intent.direction.angle_to(offset)) <= deg_to_rad(arc_degrees*.5) and combat.unobstructed(owner.global_position,target.global_position):
				chosen=target
				distance=offset.length()
		if chosen == null: return false
		intent.target_ref=weakref(chosen)
	intent.context.freeze_modifiers()
	var runtime := SourceMoveRuntime.new()
	runtime.intent = intent
	runtime.combat = combat
	runtime.definition = self
	combat.add_child(runtime)
	return true
