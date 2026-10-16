class_name CombatFlash
extends Node2D
var radius: float = 0
var line_end: Vector2 = Vector2.ZERO
var color: Color = Color(1, 0.8, 0.3, 0.55)
var remaining: float = 0.18
func _physics_process(delta: float) -> void:
	remaining -= delta
	modulate.a = clampf(remaining / .18, 0, 1)
	if remaining <= 0: queue_free()
func _draw() -> void:
	if get_meta("art_bound",false): return
	if line_end != Vector2.ZERO: draw_line(Vector2.ZERO,line_end,color,maxf(3,radius * 2))
	elif radius > 0: draw_arc(Vector2.ZERO,radius,0,TAU,40,color,4)
