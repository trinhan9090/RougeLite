class_name EnemyTelegraph
extends Node2D
## Presentation-only warning footprint for an enemy attack.
##
## The telegraph never deals damage and never owns a timer that gameplay
## depends on: it mirrors the window the behaviour module uses, so what the
## player sees is exactly the area that will be hit.

enum Style { SLAM, RUNE, DANGER, AIM, STREAK }

var style: StringName = &"slam"
var radius: float = 60.0
var length: float = 60.0
var direction: Vector2 = Vector2.RIGHT
var duration: float = 0.55
var elapsed: float = 0.0
var tint: Color = Color.WHITE

func _ready() -> void:
	z_index = 20 # Gameplay warning must stay above cosmetic skill effects.
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
	queue_redraw()

func progress() -> float:
	return clampf(elapsed / maxf(0.01, duration), 0.0, 1.0)

func _draw() -> void:
	match style:
		&"slam":
			_draw_slam()
		&"rune":
			_draw_rune()
		&"danger":
			_draw_danger()
		&"aim":
			_draw_aim()
		&"streak":
			_draw_streak()

func _draw_slam() -> void:
	var fill := Color(tint.r, tint.g, tint.b, tint.a * (0.35 + 0.35 * progress()))
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(tint.r, tint.g, tint.b, 0.95), 3.0)
	draw_arc(Vector2.ZERO, radius * (0.55 + 0.45 * progress()), 0.0, TAU, 32, Color(tint.r, tint.g, tint.b, 0.55), 2.0)

func _draw_rune() -> void:
	var fill := Color(tint.r, tint.g, tint.b, tint.a * 0.22)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(tint.r, tint.g, tint.b, 0.9), 3.0)
	draw_arc(Vector2.ZERO, radius * 0.82, 0.0, TAU, 40, Color(tint.r, tint.g, tint.b, 0.5), 1.5)
	# Inscribed rune ticks.
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var inner := Vector2.from_angle(angle) * radius * 0.82
		var outer := Vector2.from_angle(angle) * radius
		draw_line(inner, outer, Color(tint.r, tint.g, tint.b, 0.75), 2.0)
	# Clockwise charge fill.
	var start := -PI * 0.5
	draw_arc(Vector2.ZERO, radius * 0.65, start, start + TAU * progress(), 40, Color(1.0, 0.86, 0.45, 0.9), 5.0)

func _draw_danger() -> void:
	var segments := 18
	var step := TAU / float(segments)
	for index in range(segments):
		var from := step * float(index)
		draw_arc(Vector2.ZERO, radius, from, from + step * 0.55, 4, Color(tint.r, tint.g, tint.b, 0.95), 3.5)
	var pulse := 0.5 + 0.5 * sin(progress() * TAU * 6.0)
	draw_circle(Vector2.ZERO, radius * (0.35 + 0.25 * pulse), Color(tint.r, tint.g, tint.b, 0.18 + 0.14 * pulse))
	draw_arc(Vector2.ZERO, radius * 0.45, 0.0, TAU, 24, Color(1.0, 1.0, 0.6, 0.8), 2.0)

func _draw_aim() -> void:
	var tip := direction.normalized() * length
	draw_line(Vector2.ZERO, tip, Color(tint.r, tint.g, tint.b, 0.35), 5.0)
	draw_line(Vector2.ZERO, tip, Color(tint.r, tint.g, tint.b, 0.95), 1.5)
	draw_arc(tip, 9.0, 0.0, TAU, 16, Color(tint.r, tint.g, tint.b, 0.95), 2.0)
	draw_line(tip - direction.orthogonal() * 9.0, tip + direction.orthogonal() * 9.0, Color(tint.r, tint.g, tint.b, 0.95), 2.0)

func _draw_streak() -> void:
	var forward := direction.normalized()
	var side := forward.orthogonal()
	var tip := forward * radius
	draw_line(-forward * radius * 0.4, tip, Color(tint.r, tint.g, tint.b, 0.5), 3.0)
	draw_colored_polygon(PackedVector2Array([tip + forward * 7.0, tip + side * 5.0, tip - side * 5.0]), Color(tint.r, tint.g, tint.b, 0.8))
