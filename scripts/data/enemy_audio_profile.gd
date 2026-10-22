class_name EnemyAudioProfile
extends Resource
## Procedural SFX descriptors for one enemy archetype.
##
## Every cue is a tone recipe rendered to an AudioStreamWAV at runtime by
## EnemyAudioService, so no binary audio asset is required and every archetype
## gets an audibly distinct signature.
##
## Cue keys used by the runtime: "step", "windup", "attack", "impact",
## "warning", "death". A cue entry is a Dictionary with:
##   freq      float  start frequency in Hz (required, > 0)
##   freq_end  float  end frequency in Hz (optional; sweep when present)
##   duration  float  seconds (required, > 0)
##   wave      String "sine" | "square" | "saw" | "noise" (optional)
##   noise     float  0..1 noise mix (optional)
##   gain      float  0..1 amplitude (optional, default 1)

const REQUIRED_CUES: Array[StringName] = [&"step", &"attack", &"death"]

@export var cues: Dictionary = {}

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if cues.is_empty():
		errors.append("enemy audio profile: at least one cue is required")
	for cue: StringName in REQUIRED_CUES:
		if not cues.has(cue):
			errors.append("enemy audio profile: missing required cue '%s'" % cue)
	for key: Variant in cues.keys():
		var name := String(key)
		if not (cues[key] is Dictionary):
			errors.append("enemy audio profile: cue '%s' must be a Dictionary" % name)
			continue
		var entry: Dictionary = cues[key]
		if not entry.has("freq") or not (entry["freq"] is float or entry["freq"] is int):
			errors.append("enemy audio profile: cue '%s' needs a numeric freq" % name)
			continue
		if not entry.has("duration") or not (entry["duration"] is float or entry["duration"] is int):
			errors.append("enemy audio profile: cue '%s' needs a numeric duration" % name)
			continue
		var frequency := float(entry["freq"])
		var duration := float(entry["duration"])
		if not is_finite(frequency) or frequency <= 0.0:
			errors.append("enemy audio profile: cue '%s' freq must be finite and positive" % name)
		if not is_finite(duration) or duration <= 0.0:
			errors.append("enemy audio profile: cue '%s' duration must be finite and positive" % name)
		if entry.has("freq_end"):
			var end_frequency := float(entry["freq_end"])
			if not is_finite(end_frequency) or end_frequency <= 0.0:
				errors.append("enemy audio profile: cue '%s' freq_end must be finite and positive" % name)
		if entry.has("noise"):
			var noise := float(entry["noise"])
			if not is_finite(noise) or noise < 0.0 or noise > 1.0:
				errors.append("enemy audio profile: cue '%s' noise must be in [0,1]" % name)
		if entry.has("gain"):
			var gain := float(entry["gain"])
			if not is_finite(gain) or gain < 0.0 or gain > 1.0:
				errors.append("enemy audio profile: cue '%s' gain must be in [0,1]" % name)
		if entry.has("wave"):
			var wave := String(entry["wave"])
			if wave not in ["sine", "square", "saw", "noise"]:
				errors.append("enemy audio profile: cue '%s' has unknown wave '%s'" % [name, wave])
	return errors
