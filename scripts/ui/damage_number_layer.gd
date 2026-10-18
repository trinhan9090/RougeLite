class_name DamageNumberLayer
extends Node2D
var combat: CombatService
var displayed: int=0
const LIMIT: int=128
func _ready() -> void:
	z_index=30
	combat.visual_event.connect(_on_event)
func _on_event(event: Dictionary) -> void:
	if event.kind!="damage_number": return
	if get_child_count()>=LIMIT: get_child(0).free()
	var number := FloatingDamageNumber.new()
	number.amount=event.amount
	number.critical=event.critical
	number.follow=event.follow
	number.height=event.height
	number.origin=event.position
	number.horizontal_offset=((displayed%5)-2)*5
	add_child(number)
	displayed+=1
func clear() -> void:
	for node in get_children(): node.free()
