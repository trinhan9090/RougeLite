class_name SourceSpriteEffect
extends Node2D
## Source AIR frame rhythm; gameplay owns all geometry and lifetimes.
var sequence_name: String = "beam"
var duration: float = .35
var pixel_scale: float = 1
var beam_size: Vector2 = Vector2.ZERO
var follow: WeakRef
var mirrored: bool = false
var slash_radius: float = 140
var slash_arc: float = 1.48353
var _elapsed: float = 0
var _frame_time: float = 0
var _index: int = 0
var _sequence: Array = []
var _textures: Dictionary = {}
static var _manifest: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _manifest.is_empty(): _manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/private_atyu/manifest.json"))
	set_sequence(sequence_name)

func set_sequence(value: String) -> void:
	sequence_name = value
	_sequence = _manifest[value].sequence if _manifest.has(value) and _manifest[value].has("sequence") else []
	_index = 0
	_frame_time = 0
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	_frame_time += delta
	if follow != null:
		var actor := follow.get_ref() as Actor
		if not is_instance_valid(actor) or not actor.health.is_alive(): queue_free();return
		if sequence_name == "seal" and actor.statuses.movement_factor() > 0: queue_free();return
		global_position = actor.hit_position()
	if _elapsed >= duration: queue_free();return
	while not _sequence.is_empty() and _frame_time >= float(_sequence[_index].ticks)/60:
		_frame_time -= float(_sequence[_index].ticks)/60
		_index = (_index+1)%_sequence.size()
	queue_redraw()

func _draw() -> void:
	if sequence_name == "slash":
		var fade: float = maxf(0,1-_elapsed/duration)
		draw_arc(Vector2.ZERO,slash_radius,-slash_arc*.5,slash_arc*.5,24,Color(.75,.65,1,fade),3)
		draw_arc(Vector2.ZERO,slash_radius-6,-slash_arc*.4,slash_arc*.4,20,Color(1,1,1,fade),2)
		return
	if _sequence.is_empty(): return
	if sequence_name == "seal":
		var phase: float = _elapsed*3
		draw_arc(Vector2.ZERO,20,phase,phase+TAU*.85,24,Color(.75,.55,1,.85),2)
		for i in range(6):
			var p: Vector2 = Vector2.from_angle(i*TAU/6+phase)*22
			draw_line(p,p*.65,Color(.9,.8,1),2)
		return
	var f: Dictionary = _sequence[_index]
	var file: String = f.file
	if not _textures.has(file): _textures[file] = load("res://assets/private_atyu/"+file)
	var texture := _textures[file] as Texture2D
	if beam_size != Vector2.ZERO:
		draw_texture_rect(texture,Rect2(Vector2(0,-beam_size.y*.5),beam_size),false)
	else:
		var size_px: Vector2 = texture.get_size()*pixel_scale
		var p := Vector2(float(f.offset[0])-float(f.axis[0]),float(f.offset[1])-float(f.axis[1]))*pixel_scale
		if mirrored:
			p.x = -p.x
			size_px.x = -size_px.x
		draw_texture_rect(texture,Rect2(p,size_px),false)
