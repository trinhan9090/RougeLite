class_name MappedSpriteEffect
extends Node2D
var sequence: Array = []
var textures: Array[Texture2D] = []
var size_px: Vector2 = Vector2(28,14)
var lifetime: float = .3
var persistent: bool = false
var elapsed: float = 0
var follow: WeakRef
var orbit_index: int = -1
var fan_degrees: float = 0
var caster: WeakRef
var cancel_on_stun: bool = false
var show_lane_boundary: bool = false
var _ticks: float = 0
var _frame: int = 0
var _period_ticks: float = 0

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for row: Dictionary in sequence:
		textures.append(load(row.path) as Texture2D)
		_period_ticks+=float(row.ticks)

func _process(delta: float) -> void:
	if caster!=null:
		var owner := caster.get_ref() as Actor
		if not is_instance_valid(owner) or not owner.health.is_alive() or (cancel_on_stun and owner.statuses.stunned()):queue_free();return
	elapsed+=delta
	if _period_ticks>0:
		_ticks=fmod(_ticks+delta*60,_period_ticks)
		for step in range(sequence.size()):
			if _ticks<float(sequence[_frame].ticks): break
			_ticks-=float(sequence[_frame].ticks)
			_frame=(_frame+1)%sequence.size()
	if follow!=null:
		var runtime := follow.get_ref() as ControlMageRuntime
		if not is_instance_valid(runtime) or runtime.is_queued_for_deletion(): queue_free();return
		if orbit_index>=0:
			var owner: Actor=runtime.intent.source()
			var angle: float=runtime.elapsed*runtime.definition.orbit_speeds[runtime.intent.rank.rank-1]+orbit_index*TAU/runtime.intent.rank.projectile_count
			global_position=owner.global_position+Vector2.from_angle(angle)*runtime.combat.modified_radius(runtime.intent)
			z_index=1 if sin(angle)>0 else -1
	if not persistent and elapsed>=lifetime:queue_free();return
	queue_redraw()

func _draw() -> void:
	if fan_degrees>0:
		var points:=PackedVector2Array([Vector2.ZERO])
		for index in range(17):points.append(Vector2.from_angle(deg_to_rad(-fan_degrees*.5+fan_degrees*index/16))*size_px.x)
		draw_colored_polygon(points,Color(.196,.788,.404,.10))
		draw_polyline(points,Color(.64,1,.70,.65),1)
		return
	if textures.is_empty(): return
	var fade: float=1 if persistent else minf(1,(lifetime-elapsed)*12)
	draw_texture_rect(textures[_frame],Rect2(-size_px*.5,size_px),false,Color(1,1,1,fade))
	if show_lane_boundary:
		draw_rect(Rect2(-size_px*.5,size_px),Color(.45,1,.6,.35*fade),false,1)
	if orbit_index>=0:draw_arc(Vector2.ZERO,10,0,TAU,16,Color("32c967"),1)
