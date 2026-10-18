class_name CombatVisualEffect
extends Node2D
signal finished(effect: CombatVisualEffect)
## Cosmetic only. Radius/length are copied from executed combat geometry.
var kind: String = "impact"
var style: String = ""
var color: Color = Color.CYAN
var radius: float = 20
var line_end: Vector2 = Vector2.ZERO
var duration: float = .3
var remaining: float = .3
var follow: WeakRef
var persistent: bool = false
var pooled: bool = false
var elapsed: float = 0
func _ready() -> void:
	# A projectile's parent transform supplies movement/rotation. Its local art
	# is immutable, so cache the draw commands instead of rebuilding each frame.
	if persistent and kind == "projectile" and follow == null: set_process(false)
func _finish() -> void:
	if pooled: finished.emit(self)
	else: queue_free()
func _process(delta: float) -> void:
	elapsed += delta
	if follow != null:
		var node := follow.get_ref() as Node2D
		if not is_instance_valid(node):
			_finish()
			return
		global_position = node.global_position
		if kind == "status" and node is Actor:
			var actor := node as Actor
			if not actor.health.is_alive() or actor.statuses.movement_factor() > 0:
				_finish()
				return
	if not persistent:
		remaining -= delta
		if remaining <= 0:
			_finish()
			return
	queue_redraw()
func _draw() -> void:
	var t: float = clampf(remaining/maxf(.001,duration),0,1)
	var fade := Color(color,t*.8)
	if kind == "projectile":
		var tail: float = 28 if style in ["piercing","barrage"] else 16
		draw_line(Vector2(-tail,0),Vector2(5,0),color,3,false)
		draw_rect(Rect2(-3,-2,7,4),Color.WHITE)
		if style in ["orb","snare"]:
			draw_circle(Vector2.ZERO,6,color,false,2,false)
		if style in ["snare","storm"]:
			draw_line(Vector2(0,-8),Vector2(0,8),color,2,false)
	elif kind == "beam":
		draw_line(Vector2.ZERO,line_end,Color(color,.18*t),radius*2,false)
		draw_line(Vector2.ZERO,line_end,fade,maxf(2,radius*.6),false)
		draw_line(Vector2.ZERO,line_end,Color(1,1,1,t),2,false)
	elif kind in ["area","shield","buff"]:
		draw_circle(Vector2.ZERO,radius,Color(color,.08*t),true,-1,false)
		draw_arc(Vector2.ZERO,radius,0,TAU,48,fade,2,false)
		if style in ["slam","charge","roll"]:
			draw_arc(Vector2.ZERO,radius*(1-t*.7),0,TAU,32,fade,3,false)
		if style == "sigil":
			for index in range(6):
				var a := Vector2.from_angle(index*TAU/6)*radius*.8
				var b := Vector2.from_angle((index+2)*TAU/6)*radius*.8
				draw_line(a,b,Color(color,t*.25),1,false)
		for index in range(8):
			var point := Vector2.from_angle(index*TAU/8)*radius
			draw_rect(Rect2(point-Vector2(2,2),Vector2(4,4)),fade)
	elif kind == "slash":
		draw_arc(Vector2.ZERO,radius,-.85,.85,16,fade,5,false)
	else:
		for index in range(6):
			var direction := Vector2.from_angle(index*TAU/6)
			draw_line(direction*radius*(1-t),direction*radius*(1-t+.25),fade,2,false)
