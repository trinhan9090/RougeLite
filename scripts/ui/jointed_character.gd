class_name JointedCharacter
extends Node2D
## Locally authored articulated placeholder: shoulders/elbows, hips/knees, torso/head.
var actor: PlayerActor
var weapon: String = "staff"
var phase: float = 0
func _physics_process(delta: float) -> void:
	phase += delta * (12 if actor.velocity.length() > 5 else 2)
	scale = Vector2.ONE * (PlayerActor.VISUAL_HEIGHT / 57.0) * (1.25 if actor.factor(&"max_hp") > 1 else 1)
	position.y = 20-23*scale.y
	queue_redraw()
func limb(a: Vector2,b: Vector2,c: Vector2,color: Color,width: float) -> void:
	draw_line(a,b,color,width)
	draw_line(b,c,color.lightened(.12),width-1)
	draw_circle(b,width*.45,color.lightened(.2))
func _draw() -> void:
	if actor == null: return
	var gait: float = sin(phase) * (1 if actor.velocity.length() > 5 else .12)
	var facing: float = -1 if actor.facing.x < 0 else 1
	var cast: float = actor.attack_flash/.12
	var body: Color = actor.tint
	draw_set_transform(Vector2.ZERO, -.3*facing if actor.motion_active else 0,Vector2(facing,1))
	draw_circle(Vector2(0,13),18,Color(0,0,0,.25))
	limb(Vector2(-6,4),Vector2(-8,14+gait*3),Vector2(-7-gait*5,23),body.darkened(.4),7)
	limb(Vector2(6,4),Vector2(8,14-gait*3),Vector2(7+gait*5,23),body.darkened(.3),7)
	draw_colored_polygon(PackedVector2Array([Vector2(-11,-15),Vector2(10,-15),Vector2(13,8),Vector2(-13,8)]),body)
	limb(Vector2(-10,-12),Vector2(-16,-3-gait*4),Vector2(-19+cast*8,4-gait*5),body.darkened(.2),6)
	var hand := Vector2(20+cast*12,-2-cast*12)
	limb(Vector2(10,-12),Vector2(17,-7+gait*3),hand,body.lightened(.2),6)
	draw_rect(Rect2(-9,-31,18,17),Color("e7c4ac"))
	draw_rect(Rect2(-10,-34,20,8),body.darkened(.5))
	draw_rect(Rect2(3*facing,-25,3,3),Color("142435"))
	if weapon == "staff":
		draw_line(hand+Vector2(0,-26),hand+Vector2(0,21),Color("d9bd84"),4)
		draw_circle(hand+Vector2(0,-28),7,Color("c1f6ff"))
	elif weapon == "pistols":
		draw_rect(Rect2(hand,Vector2(17,-7)),Color("d9dfe9"))
		draw_rect(Rect2(-26,0,14,6),Color("a3afc4"))
	else:
		draw_line(hand,hand+Vector2(5,-25),Color("c7a781"),5)
		draw_rect(Rect2(hand+Vector2(-7,-31),Vector2(28,15)),Color("aeb6cb"))
