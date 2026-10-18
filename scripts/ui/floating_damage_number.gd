class_name FloatingDamageNumber
extends Node2D
var amount: float=0
var critical: bool=false
var follow: WeakRef
var height: float=48
var horizontal_offset: float=0
var origin: Vector2
var age: float=0
var duration: float=.75
var caption: Label
var _anchor: Vector2
func _ready() -> void:
	_anchor=origin
	global_position=_anchor+Vector2(horizontal_offset,-height)
	caption=Label.new()
	caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
	caption.text=("%.1f"%amount)+("!" if critical else "")
	caption.position=Vector2(-50,-24)
	caption.custom_minimum_size=Vector2(100,24)
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",18 if critical else 14)
	caption.add_theme_color_override("font_color",Color("ffe068") if critical else Color.WHITE)
	caption.add_theme_color_override("font_outline_color",Color("12121d"))
	caption.add_theme_constant_override("outline_size",4)
	add_child(caption)
func _process(delta: float) -> void:
	age+=delta
	if age>=duration: queue_free();return
	var target: Actor=follow.get_ref() as Actor if follow!=null else null
	if is_instance_valid(target): _anchor=target.hit_position()
	global_position=_anchor+Vector2(horizontal_offset,-height-age*32)
	modulate.a=minf(1,(duration-age)/.25)
