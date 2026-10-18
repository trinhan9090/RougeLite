class_name SourceMoveRuntime
extends Node2D
## Per-cast state. No mutable state stored on content Resources.
var intent: CastIntent
var combat: CombatService
var definition: SourceMoveExecutor
var elapsed: float = 0
var strikes: int = 0
var resolved: bool = false
var companion_visual: SourceSpriteEffect

func _ready() -> void:
	if definition.move == "companion":
		intent.source().set_meta("companion_runtime",weakref(self))
		companion_visual = SourceSpriteEffect.new()
		companion_visual.sequence_name = "companion"
		companion_visual.duration = intent.rank.duration
		companion_visual.pixel_scale = .85
		add_child(companion_visual)
	global_position = intent.source().global_position
	if definition.move == "companion": _audio_cue(intent.source(), &"companion")

func _physics_process(delta: float) -> void:
	var owner: Actor = intent.source()
	if not is_instance_valid(owner) or not owner.health.is_alive():
		queue_free()
		return
	elapsed += delta
	if definition.move == "companion":
		global_position = owner.global_position + Vector2(-32,-14)
		if elapsed >= definition.windup + strikes * definition.tick_interval:
			var target: Actor = TargetingService.nearest(owner,combat.actors(),intent.rank.range_px)
			if target != null:
				# Native periodic hits remain primary like area ticks. Each strike
				# still spends the root budget; generated augments remain children.
				var child: CombatContext = intent.context.event_copy() if intent.context.budget.spend_proc(1) else null
				if child != null:
					combat.hit(owner,target,intent.rank,child)
					companion_visual.set_sequence("companion_attack")
					_audio_cue(owner, &"companion_attack")
					companion_visual.mirrored = target.global_position.x < global_position.x
			strikes += 1
		if elapsed >= intent.rank.duration: queue_free()
		return
	if not resolved and elapsed >= definition.windup:
		resolved = true
		if owner.statuses.stunned():
			queue_free()
			return
		resolve_move(owner)
		queue_free()

func resolve_move(owner: Actor) -> void:
	var ids: Dictionary[int,bool] = {}
	if definition.move == "cone":
		var radius: float = combat.modified_radius(intent)
		for target in combat.actors():
			var offset: Vector2 = target.global_position-owner.global_position
			if target.team != owner.team and offset.length() <= radius and absf(intent.direction.angle_to(offset)) <= deg_to_rad(definition.arc_degrees*.5) and combat.unobstructed(owner.global_position,target.global_position):
				combat.deliver(intent,target,null,ids)
		var fx := SourceSpriteEffect.new()
		fx.sequence_name = "slash"
		fx.duration = .2
		fx.slash_radius = radius
		fx.slash_arc = deg_to_rad(definition.arc_degrees)
		fx.rotation = intent.direction.angle()
		combat.add_child(fx)
		fx.global_position = owner.global_position
		_audio_cue(owner, &"cone")
	elif definition.move == "control":
		var target: Actor = intent.target()
		if not is_instance_valid(target) or not target.health.is_alive() or target.team == owner.team or owner.global_position.distance_to(target.global_position)>intent.rank.range_px or not combat.unobstructed(owner.global_position,target.global_position): return
		if intent.manual and absf(intent.direction.angle_to(owner.global_position.direction_to(target.global_position))) > deg_to_rad(42.5): return
		var status := definition.status.duplicate(true) as StatusEffectDefinition
		status.duration = intent.rank.duration
		target.statuses.apply(status,target.is_boss)
		if target.statuses.movement_factor() > 0: return
		var fx := SourceSpriteEffect.new()
		fx.sequence_name = "seal"
		fx.duration = .15 if target.is_boss else status.duration
		fx.pixel_scale = .15
		fx.follow = weakref(target)
		combat.add_child(fx)
		fx.global_position = target.hit_position()
		_audio_cue(owner, &"control")
	elif definition.move == "charged_beam":
		var old: WeakRef = owner.get_meta("companion_runtime") as WeakRef if owner.has_meta("companion_runtime") else null
		var active: bool = old != null and is_instance_valid(old.get_ref())
		var applied := intent.rank.duplicate(true) as SkillRankDefinition
		if active: applied.damage *= 1.25
		var origin: Vector2 = combat.cast_origin(owner)
		for target in combat.beam_receivers(owner,origin,intent.direction,applied.range_px,combat.modified_radius(intent)):
			combat.hit(owner,target,applied,intent.context)
		var fx := SourceSpriteEffect.new()
		fx.sequence_name = "beam"
		fx.duration = .35
		fx.beam_size = Vector2(applied.range_px,combat.modified_radius(intent)*2)
		fx.rotation = intent.direction.angle()
		combat.add_child(fx)
		fx.global_position = origin
		_audio_cue(owner, &"charged_beam")

func _audio_cue(owner: Actor, cue: StringName) -> void:
	var adapter := owner.get_node_or_null("ActionAudio") as ActionAudio
	if adapter != null: adapter.play_cue(cue)

func _exit_tree() -> void:
	var owner: Actor = intent.source() if intent != null else null
	if definition != null and definition.move == "companion" and is_instance_valid(owner):
		var old: WeakRef = owner.get_meta("companion_runtime") as WeakRef if owner.has_meta("companion_runtime") else null
		if old != null and old.get_ref() == self: owner.remove_meta("companion_runtime")
