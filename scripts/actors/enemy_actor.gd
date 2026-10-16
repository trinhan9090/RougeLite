class_name EnemyActor
extends Actor

@export var definition: EnemyDefinition
var _target: WeakRef
var navigation: Callable

func _ready() -> void:
	stats_definition = definition.stats
	team = 2
	super._ready()

func set_target(actor: Actor) -> void:
	_target = weakref(actor)

func _physics_process(delta: float) -> void:
	advance_effects(delta)
	var target: Actor = _target.get_ref() as Actor if _target != null else null
	if not is_instance_valid(target) or not target.health.is_alive():
		velocity = Vector2.ZERO
		return
	var offset: Vector2 = target.global_position - global_position
	var direction: Vector2 = offset.normalized() if offset.length() > (44 if is_boss else 26) else Vector2.ZERO
	if direction != Vector2.ZERO and navigation.is_valid():
		# The arena caches the shared flow field; steering must still use the
		# current body position every physics tick to avoid overshooting turns.
		direction = navigation.call(global_position,target.global_position)
	MovementController.move(self, direction, stats.move_speed * statuses.movement_factor())

func _draw() -> void:
	draw_circle(Vector2(0, 6), 16, Color(0, 0, 0, 0.3))
	draw_circle(Vector2.ZERO, 13, Color("ea7078"))
	draw_circle(Vector2(-4, -3), 2, Color("451c2b"))
	draw_circle(Vector2(4, -3), 2, Color("451c2b"))
	if health != null and health.current < health.maximum:
		draw_rect(Rect2(-16, -23, 32, 4), Color("3c2533"))
		draw_rect(Rect2(-16, -23, 32 * health.current / health.maximum, 4), Color("f0b46a"))
