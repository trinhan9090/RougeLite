class_name ActionAudio
extends Node2D
## Per-actor, data-configured presentation. No gameplay timers or content mutation.
const VOICE_LIMIT: int = 12
const QUEUE_LIMIT: int = 64
var actor: PlayerActor
var profile: Dictionary = {}
var pending: Array[Dictionary] = []
var voices: Array[AudioStreamPlayer2D] = []
var dispatched: Dictionary[String, int] = {}
var voices_started: int = 0
var _streams: Dictionary[String, AudioStream] = {}

func _ready() -> void:
	var path: String = actor.visual_frames.get_meta("audio_profile", "")
	profile = JSON.parse_string(FileAccess.get_file_as_string(path))
	for cue: String in profile:
		for item: Dictionary in profile[cue]:
			var stream := load(item.path) as AudioStream
			assert(stream != null, "Missing mapped audio: " + String(item.path))
			_streams[item.path] = stream
	for index in range(VOICE_LIMIT):
		var voice := AudioStreamPlayer2D.new()
		voice.max_distance = 1600
		voice.attenuation = .5
		add_child(voice)
		voices.append(voice)
	actor.sprite_visual.action_started.connect(play_cue)
	actor.health.depleted.connect(clear)

func play_cue(cue: StringName) -> void:
	if not actor.health.is_alive() or get_tree().paused: return
	for item: Dictionary in profile.get(String(cue), []):
		if pending.size() >= QUEUE_LIMIT: pending.pop_front()
		pending.append({"cue":String(cue),"left":float(item.delay),"path":item.path,"db":item.db})
	_flush(0)

func play_impact(skill_id: StringName) -> void:
	var specific: StringName=StringName("impact:"+String(skill_id))
	play_cue(specific if profile.has(String(specific)) else &"impact")

func _physics_process(delta: float) -> void:
	_flush(delta)

func _flush(delta: float) -> void:
	if not actor.health.is_alive():
		clear()
		return
	for index in range(pending.size()-1,-1,-1):
		pending[index].left -= delta
		if pending[index].left > .000001: continue
		var item: Dictionary = pending[index]
		pending.remove_at(index)
		var cue: String = item.cue
		dispatched[cue] = dispatched.get(cue,0)+1
		# Dummy headless audio does not prove audible playback.
		if DisplayServer.get_name() == "headless": continue
		var selected: AudioStreamPlayer2D = voices[0]
		for voice in voices:
			if not voice.playing:
				selected = voice
				break
		selected.stop()
		selected.stream = _streams[item.path]
		selected.volume_db = float(item.db)
		selected.play()
		voices_started += 1

func clear() -> void:
	pending.clear()
	for voice in voices: voice.stop()
