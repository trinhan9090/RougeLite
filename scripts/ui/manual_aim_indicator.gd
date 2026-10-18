class_name ManualAimIndicator
extends Node2D
## Ground-plane presentation; attack direction is runtime actor state.
var actor: PlayerActor
func _ready() -> void:
	z_index = -1
	position = Vector2(0,5)
func _process(_delta: float) -> void:
	visible = is_instance_valid(actor) and actor.manual_aim and actor.health.is_alive()
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(actor): return
	var angle: float = actor.attack_direction.angle()
	var points := PackedVector2Array()
	for i in range(41):
		var point: Vector2 = Vector2.from_angle(angle-1.0+2.0*i/40)*30
		point.y *= .38
		points.append(point)
	draw_polyline(points,Color("73e8ff"),1.5,true)
	var tip: Vector2 = actor.attack_direction*40
	var base: Vector2 = actor.attack_direction*30
	var side: Vector2 = actor.attack_direction.orthogonal()*5
	var polygon := PackedVector2Array([tip,base+side,base-side])
	for i in range(polygon.size()): polygon[i].y *= .38
	draw_colored_polygon(polygon,Color("73e8ff"))
