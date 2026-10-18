class_name PixelVisualEffect
extends CelestialVisualEffect
## Frame-sheet renderer; lifecycle is inherited from the actual shield/status binding.
const SHEETS: Dictionary = {
	"bolt": preload("res://assets/art_v3/vfx/bolt.png"),
	"snare": preload("res://assets/art_v3/vfx/snare.png"),
	"impact": preload("res://assets/art_v3/vfx/impact.png"),
	"cast": preload("res://assets/art_v3/vfx/cast.png"),
	"area": preload("res://assets/art_v3/vfx/area.png"),
	"shield": preload("res://assets/art_v3/vfx/shield.png"),
	"status": preload("res://assets/art_v3/vfx/status.png"),
	"beam": preload("res://assets/art_v3/vfx/beam.png")}
const EXTRA: Dictionary={
	"haste":preload("res://assets/art_v3/vfx/haste.png"),
	"bullet":preload("res://assets/art_v3/vfx/bullet.png"),"piercing":preload("res://assets/art_v3/vfx/piercing.png"),
	"muzzle":preload("res://assets/art_v3/vfx/muzzle.png"),"brass_impact":preload("res://assets/art_v3/vfx/brass_impact.png"),
	"dust":preload("res://assets/art_v3/vfx/dust.png"),"slash":preload("res://assets/art_v3/vfx/slash.png"),
	"slam":preload("res://assets/art_v3/vfx/slam.png"),"iron":preload("res://assets/art_v3/vfx/iron.png"),
	"titan":preload("res://assets/art_v3/vfx/titan.png"),"charge":preload("res://assets/art_v3/vfx/charge.png")}
const GUN_STYLES: Array[String]=["bullet","tracer","barrage","piercing","storm"]
var bound_buff: StringName=&""
func _body_center_offset()->Vector2:
	var owner_actor:PlayerActor=follow.get_ref() as PlayerActor if follow!=null else null
	if is_instance_valid(owner_actor) and is_instance_valid(owner_actor.sprite_visual):
		var visual:ActorSprite=owner_actor.sprite_visual
		var feet:Vector2=visual.sprite_frames.get_meta("feet_anchor",Vector2(48,76))
		var center:Vector2=visual.sprite_frames.get_meta("body_center",Vector2(48,52))
		return (center-feet)*visual.scale
	return Vector2(0,-24)
func _process(delta: float) -> void:
	if bound_buff!=&"":
		var owner_actor: Actor=follow.get_ref() as Actor if follow!=null else null
		if not is_instance_valid(owner_actor) or not owner_actor.health.is_alive() or not owner_actor.buffs.has(bound_buff):
			_finish();return
	super._process(delta)
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(true)
func _draw() -> void:
	var id: String = kind
	if kind == "projectile": id = "snare" if style == "snare" else "bolt"
	if kind=="projectile" and style in GUN_STYLES: id="piercing" if style=="piercing" else "bullet"
	if kind=="cast" and style in GUN_STYLES:id="muzzle"
	if kind=="impact" and style in GUN_STYLES:id="brass_impact"
	if kind=="impact" and style in ["sword","slam","resolve","charge","titan"]:id="brass_impact"
	if kind=="slash":id="slash"
	if kind=="shield" and style=="resolve":id="iron"
	if kind=="guard_hit":id="iron" if style=="resolve" else "shield"
	if kind=="buff":id="haste" if style=="roll" else "titan"
	if kind=="dash":id="dust" if style=="roll" else "charge"
	if kind=="ricochet":id="piercing"
	if kind=="burn_line":id="charge" if style=="charge" else "beam"
	if kind=="area" and style in ["slam","sword","heavy","charge","resolve","titan"]:id="slam" if radius>30 else "charge"
	if kind=="area" and style=="roll":id="dust"
	if not SHEETS.has(id) and not EXTRA.has(id): id = "impact"
	var sheet: Texture2D = EXTRA[id] if EXTRA.has(id) else SHEETS[id]
	var size := Vector2(sheet.get_width()/6.0,sheet.get_height())
	var index: int = int(elapsed*14)%6 if persistent else mini(5,int(elapsed/maxf(.001,duration)*6))
	var source := Rect2(Vector2(size.x*index,0),size)
	var target := Rect2(-size*.5,size)
	var alpha: float = 1.0 if persistent else clampf(remaining/maxf(duration,.001)*3,0,1)
	if kind == "area":
		target = Rect2(Vector2.ONE*-radius,Vector2.ONE*radius*2)
		alpha *= .78
	elif kind=="slash": target=Rect2(Vector2.ONE*-radius,Vector2.ONE*radius*2)
	elif kind=="dash": target=Rect2(-38,-20,64,40)
	elif kind=="buff": target=Rect2(-16,-9,32,16) if style=="roll" else Rect2(_body_center_offset()-Vector2(40,40),Vector2(80,80))
	elif kind == "shield":
		# Decoration surrounds the compact body; it is not a damage collider.
		target = Rect2(_body_center_offset()-Vector2(36,36),Vector2(72,72))
	elif kind=="guard_hit":target=Rect2(_body_center_offset()-Vector2(18,18),Vector2(36,36))
	elif kind == "status":
		target = Rect2(-21,-24,42,42)
	elif kind in ["beam","ricochet","burn_line"]:
		# Rotate the frame strip along the real endpoint, preserving exact width.
		draw_set_transform(Vector2.ZERO,line_end.angle())
		target = Rect2(0,-radius,line_end.length(),radius*2)
	var tint:=Color(1,1,1,alpha)
	if kind=="impact" and style in ["sword","slam","resolve","charge","titan"]:tint=Color(1,.55,.6,alpha)
	draw_texture_rect_region(sheet,target,source,tint,false,false)
