class_name EnemyPixelVisual
extends Node2D
## Pure presentation: reads velocity, never navigates or deals damage.
const SHEET: Texture2D = preload("res://assets/art_v3/world/shade_enemy.png")
var actor: EnemyActor
var elapsed: float = 0
var facing: int = 0
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
func _process(delta: float) -> void:
	elapsed += delta
	if actor.velocity.length()>1:
		if absf(actor.velocity.y)>absf(actor.velocity.x): facing = 0 if actor.velocity.y>0 else 3
		else: facing = 1 if actor.velocity.x>0 else 2
	queue_redraw()
func _draw() -> void:
	var frame: int = int(elapsed*8)%4 if actor.velocity.length()>1 else 0
	draw_texture_rect_region(SHEET,Rect2(-16,-35,32,40),Rect2(frame*32,facing*40,32,40))
	if actor.mark_left>0:
		var c:=Color("e6ac61")
		for x: float in [-17.0,17.0]:
			var inward: float=-signf(x)*5
			draw_line(Vector2(x,-30),Vector2(x+inward,-30),c,1)
			draw_line(Vector2(x,-30),Vector2(x,-25),c,1)
			draw_line(Vector2(x,-6),Vector2(x+inward,-6),c,1)
