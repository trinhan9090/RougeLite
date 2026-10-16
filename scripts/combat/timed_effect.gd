class_name TimedCombatEffect
extends Node2D
var intent: CastIntent
var executor: EffectExecutorDefinition
var combat: CombatService
var remaining: float
var tick_left: float = 0.0
var hit_ids: Dictionary[int, bool] = {}
var _origin: Vector2

func _ready() -> void:
	remaining = intent.rank.duration if executor.kind == "area" else executor.dash_duration
	global_position = intent.aim_point if executor.kind == "area" else intent.source().global_position
	_origin = global_position
	if executor.kind == "dash": intent.source().motion_active = true

func _physics_process(delta: float) -> void:
	var source: Actor = intent.source()
	if not is_instance_valid(source) or not source.health.is_alive():
		finish(false)
		return
	if executor.kind == "dash":
		var travel: float = intent.rank.range_px * minf(delta, remaining) / executor.dash_duration
		var collision: KinematicCollision2D = source.move_and_collide(intent.direction * travel)
		global_position = source.global_position
		combat.radial_hit(intent, global_position, maxf(22, intent.rank.radius_px), hit_ids, executor.status)
		if collision != null: remaining = 0
	else:
		tick_left -= delta
		if tick_left <= 0:
			var tick_ids: Dictionary[int, bool] = {}
			combat.radial_hit(intent, global_position, combat.modified_radius(intent), tick_ids, executor.status)
			tick_left += executor.tick_interval
	remaining -= delta
	queue_redraw()
	if remaining <= 0: finish(true)

func finish(completed: bool) -> void:
	var source: Actor = intent.source()
	if executor.kind == "dash" and is_instance_valid(source):
		source.motion_active = false
		if completed: combat.dash_completed(intent)
		if completed and intent.rank.behavior != null and intent.rank.behavior.trail_duration > 0:
			var behavior: SkillBehaviorDefinition = intent.rank.behavior
			for tick in range(1,roundi(behavior.trail_duration / .5) + 1):
				var trail := CastIntent.new()
				trail.source_ref = intent.source_ref
				trail.context = intent.context.child(&"dash_trail")
				trail.aim_point = _origin
				trail.direction = _origin.direction_to(source.global_position)
				trail.rank = SkillRankDefinition.new()
				trail.rank.damage = behavior.trail_damage
				trail.rank.range_px = _origin.distance_to(source.global_position)
				trail.rank.radius_px = 30
				if trail.context != null: combat.schedule(tick*.5,combat.beam_tick.bind(trail))
	queue_free()

func _draw() -> void:
	if get_meta("art_bound",false): return
	if executor.kind == "area": draw_circle(Vector2.ZERO, combat.modified_radius(intent), Color(0.2, 0.65, 1, 0.22))
	else: draw_circle(Vector2.ZERO, 25, Color(1, 0.7, 0.2, 0.5))
