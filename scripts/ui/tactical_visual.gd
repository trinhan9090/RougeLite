class_name TacticalVisual
extends MappedSpriteEffect
var mine: WeakRef
var arc_start: Vector2
var arc_end: Vector2
var ballistic: bool=false
var warning_radius: float=0
var ground_radius: float=0
func _process(delta: float) -> void:
	super._process(delta)
	if mine!=null:
		var object:=mine.get_ref() as TacticalMine
		if not is_instance_valid(object) or object.is_queued_for_deletion():queue_free();return
		modulate=Color(1,1,1,.8+.2*sin(elapsed*8)) if object.armed else Color(.7,.7,.7,.65)
	if ballistic:
		var t: float=clampf(elapsed/lifetime,0,1)
		global_position=arc_start.lerp(arc_end,t)+Vector2(0,-sin(t*PI)*42)
		rotation=t*TAU*2
func _draw() -> void:
	if ground_radius>0:
		draw_circle(Vector2.ZERO,ground_radius,Color(1,.35,.08,.035))
		draw_arc(Vector2.ZERO,ground_radius,0,TAU,48,Color(1,.45,.12,.22),1)
	elif warning_radius>0:
		draw_arc(Vector2.ZERO,warning_radius,0,TAU,48,Color(1,.6,.2,.45),1)
	else:super._draw()
