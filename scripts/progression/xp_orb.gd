class_name XpOrb
extends Node2D

signal collected(amount: int)
var amount: int = 6
var definition: ProgressionDefinition
var _target: WeakRef
var _age: float = 0.0
var _collected: bool = false

func configure(player: PlayerActor, xp: int, config: ProgressionDefinition) -> void:
	_target = weakref(player)
	amount = xp
	definition = config

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= definition.orb_lifetime:
		queue_free()
		return
	var player := _target.get_ref() as PlayerActor
	if not is_instance_valid(player) or not player.health.is_alive():
		return
	var distance: float = global_position.distance_to(player.global_position)
	if distance <= definition.collect_radius:
		consume_once()
	elif distance <= player.stats.pickup_radius:
		global_position = global_position.move_toward(player.global_position, 420.0 * delta)

func consume_once() -> bool:
	if _collected:
		return false
	_collected = true
	collected.emit(amount)
	queue_free()
	return true

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8, Color(0.2, 0.9, 0.7, 0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)]), Color("66e5bc"))
