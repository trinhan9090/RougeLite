class_name BossTelegraph
extends Node2D
var combat: CombatService
var source_ref: WeakRef
var target_ref: WeakRef
var direction: Vector2 = Vector2.RIGHT
var shape: String = "circle"
var radius: float = 170
var length: float = 1000
var remaining: float = 1
var damage: float = 24
var damage_type: String = "PHYSICAL"
var resolved: bool = false
func _ready() -> void:
	z_index = 20 # Gameplay warning must remain above cosmetic skill effects.
func contains(point: Vector2) -> bool:
	var offset: Vector2 = point-global_position
	if shape == "circle": return offset.length() <= radius
	if shape == "cone": return offset.length() <= length and absf(direction.angle_to(offset)) <= PI/4
	return offset.dot(direction) >= 0 and offset.dot(direction) <= length and absf(offset.cross(direction)) <= radius
func _physics_process(delta: float) -> void:
	var source: Actor = source_ref.get_ref() as Actor
	var target: Actor = target_ref.get_ref() as Actor
	if not is_instance_valid(source) or not source.health.is_alive() or not is_instance_valid(target) or not target.health.is_alive():
		queue_free()
		return
	remaining -= delta
	if remaining <= 0:
		resolved = true
		if contains(target.global_position):
			var rank := SkillRankDefinition.new()
			rank.damage = damage
			rank.damage_type = damage_type
			combat.hit(source,target,rank,combat.next_context(source,&"skill.boss.telegraphed"))
		var flash := CombatFlash.new()
		flash.radius = radius
		if shape != "circle": flash.line_end = direction*length
		combat.add_child(flash)
		flash.global_position = global_position
		queue_free()
	queue_redraw()
func _draw() -> void:
	var color := Color(1,.25,.12,.35)
	if shape == "circle":
		draw_circle(Vector2.ZERO,radius,color)
		draw_arc(Vector2.ZERO,radius,0,TAU,48,Color.ORANGE,3)
	elif shape == "cone":
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO,direction.rotated(-PI/4)*length,direction.rotated(PI/4)*length]),color)
	else:
		draw_line(Vector2.ZERO,direction*length,color,radius*2)
		draw_line(Vector2.ZERO,direction*length,Color.ORANGE,2)
