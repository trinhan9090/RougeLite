class_name FloatingDamageNumber
extends Node2D
## Pooled damage caption. The layer reuses instances instead of allocating a
## new Label per hit, which keeps GC churn low during heavy combat.
signal expired

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
	_build_caption()
	_refresh_caption()
## Configure this instance for a new hit. Safe to call on a recycled node.
func setup(value: float,is_critical: bool,target: WeakRef,top: float,offset_x: float,start: Vector2) -> void:
	amount=value
	critical=is_critical
	follow=target
	height=top
	horizontal_offset=offset_x
	origin=start
	age=0
	_anchor=start
	_build_caption()
	_refresh_caption()
	modulate.a=1.0
	visible=true
	set_process(true)
	global_position=_anchor+Vector2(horizontal_offset,-height)
func _build_caption() -> void:
	if caption != null: return
	caption=Label.new()
	caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
	caption.text=("%.1f"%amount)+("!" if critical else "")
	caption.position=Vector2(-50,-24)
	caption.custom_minimum_size=Vector2(100,24)
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",20 if critical else 16)
	caption.add_theme_color_override("font_color",Color("fff3a0") if critical else Color.WHITE)
	caption.add_theme_color_override("font_outline_color",Color("0a0a14"))
	caption.add_theme_constant_override("outline_size",3)
	add_child(caption)
func _refresh_caption() -> void:
	if caption == null: return
	caption.text=("%.1f"%amount)+("!" if critical else "")
	caption.add_theme_font_size_override("font_size",20 if critical else 16)
	caption.add_theme_color_override("font_color",Color("fff3a0") if critical else Color.WHITE)
func _process(delta: float) -> void:
	age+=delta
	if age>=duration:
		set_process(false)
		expired.emit(self)
		return
	var target: Actor=follow.get_ref() as Actor if follow!=null else null
	if is_instance_valid(target): _anchor=target.hit_position()
	global_position=_anchor+Vector2(horizontal_offset,-height-age*32)
	modulate.a=minf(1,(duration-age)/.25)
