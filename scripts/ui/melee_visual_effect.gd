class_name MeleeVisualEffect
extends MappedSpriteEffect
var actor_ref: WeakRef
var actor_offset: Vector2=Vector2.ZERO
var runtime_ref: WeakRef
var boundary_radius: float=0
var ground: bool=false
## Opt-in source-tick retiming for one-shot impact sequences.
var complete_once: bool=false
func _process(delta: float) -> void:
	super._process(delta)
	if complete_once and _period_ticks>0 and lifetime>0:
		var remaining: float=clampf(elapsed/lifetime,0,.999999)*_period_ticks
		_frame=0
		for index in range(sequence.size()):
			_frame=index
			if remaining<float(sequence[index].ticks):break
			remaining-=float(sequence[index].ticks)
	if runtime_ref!=null:
		var runtime: Node=runtime_ref.get_ref()
		if not is_instance_valid(runtime) or runtime.is_queued_for_deletion():queue_free();return
	if actor_ref!=null:
		var actor:=actor_ref.get_ref() as Actor
		if not is_instance_valid(actor) or not actor.health.is_alive():queue_free();return
		global_position=actor.global_position+actor.cast_origin_offset+actor_offset
func _draw() -> void:
	if boundary_radius>0:
		draw_arc(Vector2.ZERO,boundary_radius,0,TAU,48,Color(.7,.55,.9,.35 if not ground else .2),1)
		if ground:draw_circle(Vector2.ZERO,boundary_radius,Color(.4,.3,.2,.055))
	super._draw()
