class_name ActorSprite
extends AnimatedSprite2D
signal action_started(action: StringName)
## Presentation-only adapter; damage and movement remain owned by gameplay.
var actor: PlayerActor
var _flash: float = 0
var _action: StringName = &""
var _playing_base: StringName = &""
var _base_scale: float = 1
var _feet_offset: float = 0
var _weapon_sprite: Sprite2D
var _was_motion: bool=false
var _combo_index: int = 0
var _side_left: bool = false
var _size_factor: float = 1.0
var _size_ready: bool = false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var reference: Texture2D = sprite_frames.get_frame_texture(_resolve(&"idle"),0)
	var used: Rect2i = reference.get_image().get_used_rect()
	_base_scale = PlayerActor.VISUAL_HEIGHT / maxf(1,used.size.y)
	_feet_offset = (used.end.y-reference.get_height()*.5)*_base_scale
	if sprite_frames.get_meta("pixel_v3",false):
		_base_scale = 1
		_feet_offset = float(sprite_frames.get_meta("feet_anchor").y)-reference.get_height()*.5
	_update_size()
	if sprite_frames.has_meta("weapon"):
		_weapon_sprite = Sprite2D.new()
		_weapon_sprite.texture = sprite_frames.get_meta("weapon") as Texture2D
		_weapon_sprite.name = "Weapon"
		add_child(_weapon_sprite)
	animation_finished.connect(func() -> void: _action = &"")
	actor.health.depleted.connect(func() -> void: play_action(&"death"))
	_play(&"idle")

func _resolve(action: StringName) -> StringName:
	if sprite_frames.get_meta("cardinal",false):
		var aliases: Dictionary = {&"attack": &"basic", &"cast": &"cast_j", &"dash": &"run"}
		action = aliases.get(action,action)
		var facing: Vector2 = actor.attack_direction if String(action) in sprite_frames.get_meta("aimed_actions",PackedStringArray()) else actor.facing
		var direction: String = "east" if facing.x >= 0 else "west"
		if absf(facing.y) > absf(facing.x): direction = "south" if facing.y > 0 else "north"
		return StringName(String(action)+"_"+direction)
	var directions: PackedStringArray = sprite_frames.get_meta("directions",PackedStringArray())
	if directions.is_empty(): return action
	var names: Array[String] = ["east","south_east","south","south_west","west","north_west","north","north_east"]
	var index: int = posmod(roundi(actor.facing.angle()/(PI/4)),8)
	return StringName(String(action)+"_"+names[index])

func _update_size() -> void:
	var factor: float = 1.25 if actor.factor(&"max_hp") > 1 else 1
	# Only touch the transform when it actually changes; this runs per actor
	# per frame and every write dirties the canvas item transform.
	if is_equal_approx(factor,_size_factor) and _size_ready:
		return
	_size_factor=factor
	_size_ready=true
	scale = Vector2.ONE * _base_scale * factor
	position = Vector2(0,(0 if sprite_frames.get_meta("pixel_v3",false) else 20)-_feet_offset*factor)

func _play(action: StringName) -> void:
	var id: StringName = _resolve(action)
	if not sprite_frames.has_animation(id): id = _resolve(&"cast")
	if animation != id:
		var previous_frame: int = frame
		var progress: float = frame_progress
		var same_action: bool = _playing_base == action
		play(id)
		if same_action: set_frame_and_progress(mini(previous_frame,sprite_frames.get_frame_count(id)-1),progress)
	_playing_base = action

func play_action(action: StringName) -> void:
	var sustained: PackedStringArray = sprite_frames.get_meta("sustained_actions",PackedStringArray())
	if String(_action) in sustained and is_playing() and (action==_action or action in [&"attack",&"basic"]): return
	var combos: PackedStringArray = sprite_frames.get_meta("combo_actions",PackedStringArray())
	if action in [&"attack",&"basic"] and not combos.is_empty():
		action = StringName(combos[_combo_index % combos.size()])
		_combo_index += 1
	# A real command arriving immediately after motion supersedes exit cleanup.
	if not actor.motion_active: _was_motion=false
	_action = action
	_play(action)
	set_frame_and_progress(int(sprite_frames.get_meta("action_start_frames",{}).get(String(action),0)),0)
	action_started.emit(action)

func _process(_delta: float) -> void:
	if not is_instance_valid(actor): return
	_update_size()
	if _weapon_sprite != null:
		var side: float = -1 if actor.facing.x < 0 else 1
		_weapon_sprite.position = Vector2(side*25,12)
		_weapon_sprite.flip_h = side < 0
		_weapon_sprite.z_index = -1 if actor.facing.y < -.5 else 1
	var directions: PackedStringArray = sprite_frames.get_meta("directions",PackedStringArray())
	var left_facing: PackedStringArray = sprite_frames.get_meta("left_facing_animations",PackedStringArray())
	flip_h = false if not directions.is_empty() else (actor.facing.x > 0 if String(_playing_base) in left_facing else actor.facing.x < 0)
	if sprite_frames.get_meta("side_view",false):
		var side_facing: Vector2 = actor.attack_direction if String(_playing_base) in sprite_frames.get_meta("aimed_actions",PackedStringArray()) else actor.facing
		if absf(side_facing.x) > .001: _side_left = side_facing.x < 0
		flip_h = _side_left
	if not actor.health.is_alive():
		_play(&"death")
		return
	if actor.motion_active:
		_was_motion=true
		_flash=actor.attack_flash
		_action = &""
		_play(StringName(sprite_frames.get_meta("motion_action",&"dash")))
		return
	if _was_motion:
		_was_motion=false
		_action=&""
		_flash=actor.attack_flash
	if actor.attack_flash > _flash and _action == &"": play_action(&"attack")
	_flash = actor.attack_flash
	if _action != &"": _play(_action)
	else: _play(&"run" if actor.velocity.length() > 5 else &"idle")
