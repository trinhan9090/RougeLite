class_name EnemyPixelVisual
extends Node2D
## Pure presentation: reads velocity and the archetype visual profile, never
## navigates or deals damage.
##
## The basic enemy keeps its original sheet and frame layout, so its sprite
## stays pixel identical. New archetypes use their own sheet, which holds one
## row per (action, facing) pair.

const SHEET: Texture2D = preload("res://assets/art_v3/world/shade_enemy.png")
const LEGACY_FRAME: int = 4
## Frames per second of every action, used to pick the cell inside a row.
const ACTION_FPS: Dictionary[StringName, float] = {
	&"idle": 3.0,
	&"walk": 8.0,
	&"windup": 6.0,
	&"attack": 12.0,
	&"hit": 1.0,
	&"death": 6.0,
}

var actor: EnemyActor
var profile: EnemyVisualProfile
var elapsed: float = 0
var facing: int = 0
var _drawn_frame: int = -1
var _drawn_facing: int = -1
var _drawn_marked: bool = false
var _drawn_state: StringName = &""
var _state_time: float = 0.0
var _last_state: StringName = &""
var _history: Array[Dictionary] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if actor != null:
		profile = actor.visual_profile

func _process(delta: float) -> void:
	elapsed += delta
	var state: StringName = actor.visual_state if actor != null else &""
	if state != _last_state:
		_last_state = state
		_state_time = 0.0
	else:
		_state_time += delta
	var moving: bool = actor.velocity.length()>1
	if actor != null and actor.facing_override != Vector2.ZERO:
		facing = _facing_from_direction(actor.facing_override)
	elif moving:
		if absf(actor.velocity.y)>absf(actor.velocity.x): facing = 0 if actor.velocity.y>0 else 3
		else: facing = 1 if actor.velocity.x>0 else 2
	# Only repaint when the visible state actually changes (8 fps walk cycle,
	# facing flip, mark overlay). A per-frame redraw is wasted fill rate.
	var action := _current_action(moving)
	var frame := _current_frame(action, moving)
	var marked: bool = actor.mark_left>0
	_track_history(moving)
	if frame==_drawn_frame and facing==_drawn_facing and marked==_drawn_marked and action==_drawn_state:
		return
	_drawn_frame=frame
	_drawn_facing=facing
	_drawn_marked=marked
	_drawn_state=action
	queue_redraw()

func _facing_from_direction(direction: Vector2) -> int:
	if absf(direction.y)>absf(direction.x): return 0 if direction.y>0 else 3
	return 1 if direction.x>0 else 2

func _current_action(moving: bool) -> StringName:
	if profile == null:
		return &"legacy"
	var state: StringName = actor.visual_state if actor != null else &""
	if state == &"death":
		return state
	if actor != null and actor.hit_flash_left > 0.0 and profile.has_action(&"hit"):
		return &"hit"
	if state != &"" and profile.has_action(state):
		return state
	if moving and profile.has_action(&"walk"):
		return &"walk"
	if profile.has_action(&"idle"):
		return &"idle"
	return profile.actions[0] if not profile.actions.is_empty() else &"idle"

func _current_frame(action: StringName, moving: bool) -> int:
	if profile == null:
		# Legacy basic enemy: a single four frame walk cycle.
		return int(elapsed*8)%LEGACY_FRAME if moving else 0
	var frames: int = profile.frames_for(action)
	if actor != null and actor.visual_state != &"" and actor.visual_state == action:
		return int(_state_time*float(ACTION_FPS.get(action, 6.0)))%frames
	if action == &"walk":
		return int(elapsed*float(ACTION_FPS[&"walk"]))%frames if moving else 0
	if action == &"idle":
		return int(elapsed*float(ACTION_FPS[&"idle"]))%frames
	return 0

func _track_history(moving: bool) -> void:
	if profile == null or not profile.afterimages:
		_history.clear()
		return
	if not moving:
		_history.clear()
		return
	_history.push_front({"position": actor.global_position, "frame": _current_frame(&"walk", true), "facing": facing})
	while _history.size() > 2:
		_history.pop_back()

func _draw() -> void:
	if profile == null:
		var frame: int = _drawn_frame if _drawn_frame>=0 else 0
		draw_texture_rect_region(SHEET,Rect2(-16,-35,32,40),Rect2(frame*32,facing*40,32,40))
	else:
		_draw_afterimages()
		var action := _drawn_state if _drawn_state != &"" else profile.actions[0]
		var frame: int = _drawn_frame if _drawn_frame>=0 else 0
		draw_texture_rect_region(profile.sheet(),profile.destination_rect(),profile.source_rect(action,facing,frame),profile.tint)
		_draw_core_glow()
	if actor.mark_left>0:
		var c:=Color("e6ac61")
		for x: float in [-17.0,17.0]:
			var inward: float=-signf(x)*5
			draw_line(Vector2(x,-30),Vector2(x+inward,-30),c,1)
			draw_line(Vector2(x,-30),Vector2(x,-25),c,1)
			draw_line(Vector2(x,-6),Vector2(x+inward,-6),c,1)

func _draw_afterimages() -> void:
	for index in range(_history.size()):
		var ghost: Dictionary = _history[index]
		var offset: Vector2 = actor.global_position - (ghost["position"] as Vector2)
		if offset.length() > 40.0:
			continue
		var alpha: float = 0.3 / float(index + 1)
		var source: Rect2 = profile.source_rect(&"walk", int(ghost["facing"]), int(ghost["frame"]))
		var destination: Rect2 = profile.destination_rect()
		destination.position += offset
		draw_texture_rect_region(profile.sheet(),destination,source,Color(0.45,0.95,1.0,alpha))

func _draw_core_glow() -> void:
	if profile.accent_pulse <= 0.0:
		return
	var pulse: float = 0.5 + 0.5*sin(elapsed*profile.accent_pulse*TAU)
	var colour: Color = profile.accent
	colour.a = 0.25 + 0.35*pulse
	draw_circle(profile.core_offset, 5.0 + 2.0*pulse, colour)
