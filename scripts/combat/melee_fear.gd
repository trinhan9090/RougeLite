class_name MeleeFear
extends Node2D
## Temporary local steering ownership. Normal enemy AI resumes on expiry/reset.
var victim_ref: WeakRef
var away_from: Vector2
var remaining: float=1
var was_processing: bool
func _ready() -> void:
	var victim:=victim_ref.get_ref() as EnemyActor
	was_processing=victim.is_physics_processing()
	var old: WeakRef=victim.get_meta("fear_motion") as WeakRef if victim.has_meta("fear_motion") else null
	if old!=null and is_instance_valid(old.get_ref()):was_processing=(old.get_ref() as MeleeFear).was_processing
	victim.set_meta("fear_motion",weakref(self));victim.set_physics_process(false)
func _physics_process(delta: float) -> void:
	var victim:=victim_ref.get_ref() as EnemyActor
	if not is_instance_valid(victim) or not victim.health.is_alive() or victim.is_queued_for_deletion():queue_free();return
	victim.advance_effects(delta)
	var direction: Vector2=(victim.global_position-away_from).normalized()
	if direction==Vector2.ZERO:direction=Vector2.RIGHT
	victim.velocity=direction*victim.stats.move_speed*victim.statuses.movement_factor()
	victim.move_and_slide()
	remaining-=delta
	if remaining<=0:queue_free()
func _exit_tree() -> void:
	var victim:=victim_ref.get_ref() as EnemyActor
	if not is_instance_valid(victim):return
	var current: WeakRef=victim.get_meta("fear_motion") as WeakRef if victim.has_meta("fear_motion") else null
	if current==null or current.get_ref()!=self:return
	victim.remove_meta("fear_motion")
	if victim.health.is_alive() and not victim.is_queued_for_deletion():victim.velocity=Vector2.ZERO;victim.set_physics_process(was_processing)
