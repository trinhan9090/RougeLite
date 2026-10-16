class_name VisualController
extends ActorSprite
## Shared four-way body/weapon scene. PlayerActor owns facing and animation commands.
@export var profile: VisualProfile
var _offhand: Sprite2D
func _ready() -> void:
	super._ready()
	if _weapon_sprite != null:
		_weapon_sprite.reparent($WeaponPivot,false)
		if int(sprite_frames.get_meta("weapon_count",1))==2:
			_offhand = Sprite2D.new()
			_offhand.texture = _weapon_sprite.texture
			_offhand.name = "OffhandWeapon"
			$WeaponPivot.add_child(_offhand)
	var shadow := $Shadow as Polygon2D
	shadow.polygon = PackedVector2Array([Vector2(-20,37),Vector2(-13,32),Vector2(13,32),Vector2(20,37),Vector2(13,42),Vector2(-13,42)])
func _process(delta: float) -> void:
	if is_instance_valid(actor) and actor.health != null and get_tree().paused and actor.health.is_alive():
		speed_scale = 0
		return
	speed_scale = 1
	super._process(delta)
	if not is_instance_valid(actor): return
	var direction: String = String(_resolve(&"idle")).trim_prefix("idle_")
	if _weapon_sprite != null and profile != null:
		_weapon_sprite.visible = actor.health.is_alive()
		_weapon_sprite.position = profile.sockets.get(direction,Vector2(25,12))
		_weapon_sprite.rotation = 0
		if _offhand != null:
			_weapon_sprite.flip_h = false
			_weapon_sprite.rotation = actor.facing.angle()
		elif _playing_base in [&"basic",&"attack",&"cast_j",&"cast_l"]:
			var count: int = sprite_frames.get_frame_count(animation)
			_weapon_sprite.rotation = actor.facing.angle()+PI*.5+(float(frame)/maxi(1,count-1)-.5)*1.8
		if _offhand != null:
			_offhand.visible = actor.health.is_alive()
			_offhand.position = Vector2(-_weapon_sprite.position.x,16)
			_offhand.flip_h = false
			_offhand.rotation = _weapon_sprite.rotation
	queue_redraw()
func _draw() -> void:
	if actor == null or actor.health == null or not actor.health.is_alive(): return
	var center := Vector2(0,12)
	if actor.health.shield_total() > 0:
		draw_arc(center,47,0,TAU,32,Color(.55,.8,1,.65),2,false)
	if actor.factor(&"max_hp") > 1:
		draw_arc(Vector2(0,37),30,0,TAU,24,Color(.9,.2,.25,.65),3,false)
	if actor.statuses.movement_factor() == 0:
		draw_rect(Rect2(-22,34,44,4),Color(.3,.8,.85,.8))
