class_name PayloadFlight
extends Node2D
## Composition: observes a real shared CombatProjectile; never duplicates collision/movement.
var projectile: CombatProjectile
var combat: CombatService
var intent: CastIntent
var detonated: bool=false
var last_position: Vector2
var on_detonate: Callable
func _ready() -> void:
	last_position=projectile.global_position
	projectile.tree_exiting.connect(_finish)
func _physics_process(_delta: float) -> void:
	if is_instance_valid(projectile):last_position=projectile.global_position
func _finish() -> void:
	if detonated:return
	detonated=true
	# Reset/map/death must never detonate removed projectiles.
	if not is_instance_valid(intent.source()) or not intent.source().health.is_alive() or combat.is_queued_for_deletion() or is_queued_for_deletion():return
	if is_instance_valid(projectile):last_position=projectile.global_position
	if on_detonate.is_valid():on_detonate.call(last_position)
	queue_free()
