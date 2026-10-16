class_name PlayerActor
extends Actor
const VISUAL_HEIGHT: float = 72.0

var facing: Vector2 = Vector2.RIGHT
var tint: Color = Color("71d8f3")
var attack_flash: float = 0.0
var rig: JointedCharacter
var weapon: String = "staff"
var manual_aim: bool = false
var visual_frames: SpriteFrames
var sprite_visual: ActorSprite

func face_toward(point: Vector2) -> void:
	var offset: Vector2 = point - global_position
	if offset.length_squared() > .0001: facing = offset.normalized()

func _ready() -> void:
	super._ready()
	if visual_frames != null:
		sprite_visual = (preload("res://scenes/characters/character_visual.tscn").instantiate() as ActorSprite) if visual_frames.get_meta("cardinal",false) else ActorSprite.new()
		sprite_visual.actor = self
		sprite_visual.sprite_frames = visual_frames
		add_child(sprite_visual)
	else:
		rig = JointedCharacter.new()
		rig.actor = self
		rig.weapon = weapon
		add_child(rig)

func _physics_process(delta: float) -> void:
	advance_effects(delta)
	if motion_active: return
	attack_flash = maxf(0.0, attack_flash - delta)
	var intent := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if intent.length_squared() > 0.0:
		facing = intent.normalized()
	MovementController.move(self, intent, minf(550, stats.move_speed * factor(&"move_speed")) * statuses.movement_factor())
	queue_redraw()

func _draw() -> void:
	if manual_aim and health != null and health.is_alive():
		var angle: float = facing.angle()
		var color := Color("73e8ff")
		draw_arc(Vector2.ZERO, 43, angle - 1.0, angle + 1.0, 40, Color(color,.65), 2.5, true)
		var tip: Vector2 = facing * 57
		var base: Vector2 = facing * 44
		var side: Vector2 = facing.orthogonal() * 7
		draw_colored_polygon(PackedVector2Array([tip,base+side,base-side]),color)
	if health != null and health.shield_total() > 0: draw_arc(Vector2.ZERO, 21, 0, TAU, 32, Color("92aaff"), 3)
	if attack_flash > 0.0 and (visual_frames == null or not visual_frames.get_meta("cardinal",false)):
		draw_arc(Vector2.ZERO, 38, facing.angle() - 0.7, facing.angle() + 0.7, 12, Color("ffe7a0"), 4)
