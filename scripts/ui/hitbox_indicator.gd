class_name HitboxIndicator
extends Node2D
## Ground ring matching the player's damage-receiving body circle.
## Enemies overlapping this circle are close enough to hit the player.

var actor: PlayerActor
var radius: float = 14.0
var _drawn_radius: float = -1.0

func _ready() -> void:
	# Behind the character art, drawn on the ground plane.
	z_index = -2
	_resolve_radius()

func _process(_delta: float) -> void:
	var alive: bool = is_instance_valid(actor) and actor.health != null and actor.health.is_alive()
	if alive != visible:
		visible = alive
		queue_redraw()
		return
	if not alive:
		return
	_resolve_radius()
	if not is_equal_approx(radius, _drawn_radius):
		_drawn_radius = radius
		queue_redraw()

func _draw() -> void:
	if not is_instance_valid(actor):
		return
	var fill := Color(0.35, 0.85, 1.0, 0.12)
	var line := Color(0.45, 0.92, 1.0, 0.8)
	draw_circle(Vector2.ZERO, radius, fill, true, -1.0, true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, line, 1.5, true)

func _resolve_radius() -> void:
	if not is_instance_valid(actor):
		return
	var shape_node := actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node != null and shape_node.shape is CircleShape2D:
		radius = (shape_node.shape as CircleShape2D).radius
