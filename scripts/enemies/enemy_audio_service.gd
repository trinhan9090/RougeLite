class_name EnemyAudioService
extends Node
## Pooled spatial audio for the enemy roster.
##
## Every cue is rendered procedurally from the archetype's authored recipe, so
## the five new enemies get audibly different signatures without shipping a
## binary asset and without reusing the player feedback tone. Voices are
## pooled and capped so a crowd spawn can never flood the mix, and the volume
## follows the distance to the listener instead of the number of hits.

const MAX_VOICES: int = 20
## Minimum time between two plays of the same cue of the same archetype.
const CUE_COOLDOWN: float = 0.05
## Distance at which an archetype cue is no longer audible.
const AUDIBLE_DISTANCE: float = 900.0

var enabled: bool = true
## Node the mix is measured against, usually the player.
var listener: Node2D

var _voices: Array[AudioStreamPlayer2D] = []
var _streams: Dictionary = {}
var _last_played: Dictionary = {}

func _ready() -> void:
	for index in range(MAX_VOICES):
		var voice := AudioStreamPlayer2D.new()
		voice.max_polyphony = 1
		voice.max_distance = AUDIBLE_DISTANCE
		voice.attenuation = 1.1
		add_child(voice)
		_voices.append(voice)

func clear() -> void:
	for voice in _voices:
		if is_instance_valid(voice):
			voice.stop()
	_last_played.clear()

## Plays one authored cue of an archetype.
func play(profile: EnemyAudioProfile, cue: StringName, position: Vector2, volume_scale: float = 1.0) -> void:
	if profile == null or not enabled:
		return
	# A headless run has no audible output; avoid creating dummy-driver playbacks.
	if DisplayServer.get_name() == "headless":
		return
	var recipe: Variant = profile.cues.get(String(cue), null)
	if not (recipe is Dictionary) or (recipe as Dictionary).is_empty():
		return
	var key := "%s/%s" % [profile.resource_path, String(cue)]
	var now := Time.get_ticks_msec() / 1000.0
	var previous: float = float(_last_played.get(key, -99.0))
	if now - previous < CUE_COOLDOWN:
		return
	_last_played[key] = now
	var voice := _free_voice()
	if voice == null:
		# Polyphony cap: drop the cue instead of stacking identical sounds.
		return
	voice.stream = _stream_for(key, recipe as Dictionary)
	voice.global_position = position
	voice.volume_db = _volume_for(position, recipe as Dictionary, volume_scale)
	voice.play()

func _free_voice() -> AudioStreamPlayer2D:
	for voice in _voices:
		if not voice.playing:
			return voice
	return null

func _volume_for(position: Vector2, recipe: Dictionary, volume_scale: float) -> float:
	var gain: float = float(recipe.get("gain", 1.0)) * maxf(0.0, volume_scale)
	var distance := 0.0
	if listener != null and is_instance_valid(listener):
		distance = listener.global_position.distance_to(position)
	var falloff: float = clampf(1.0 - distance / AUDIBLE_DISTANCE, 0.0, 1.0)
	return linear_to_db(clampf(gain * (0.3 + 0.7 * falloff), 0.001, 1.0))

func _stream_for(key: String, recipe: Dictionary) -> AudioStreamWAV:
	if _streams.has(key):
		return _streams[key]
	var stream := _render(key, recipe)
	_streams[key] = stream
	return stream

func _render(key: String, recipe: Dictionary) -> AudioStreamWAV:
	var rate := 22050
	var duration: float = maxf(0.02, float(recipe.get("duration", 0.1)))
	var freq: float = maxf(20.0, float(recipe.get("freq", 440.0)))
	var freq_end: float = maxf(20.0, float(recipe.get("freq_end", freq)))
	var wave := String(recipe.get("wave", "sine"))
	var noise: float = clampf(float(recipe.get("noise", 0.0)), 0.0, 1.0)
	var gain: float = clampf(float(recipe.get("gain", 1.0)), 0.0, 1.0)
	var samples: int = maxi(2, roundi(rate * duration))
	var data := PackedByteArray()
	data.resize(samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var phase := 0.0
	for index in range(samples):
		var t := float(index) / float(samples)
		var current: float = lerpf(freq, freq_end, t)
		phase += TAU * current / float(rate)
		var value := 0.0
		match wave:
			"sine":
				value = sin(phase)
			"square":
				value = 1.0 if sin(phase) >= 0.0 else -1.0
			"saw":
				value = fposmod(phase / TAU, 1.0) * 2.0 - 1.0
			"noise":
				value = rng.randf_range(-1.0, 1.0)
			_:
				value = sin(phase)
		if noise > 0.0:
			value = lerpf(value, rng.randf_range(-1.0, 1.0), noise)
		# Short attack and a soft decay: the cue reads as an impact instead of
		# a flat tone.
		var envelope: float = minf(1.0, t * 24.0) * pow(1.0 - t, 1.6)
		value *= gain * envelope
		data.encode_s16(index * 2, roundi(clampf(value, -1.0, 1.0) * 32000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream
