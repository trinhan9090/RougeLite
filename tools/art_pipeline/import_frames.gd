extends SceneTree
## Import separate PNGs into deterministic read-only SpriteFrames resources.
func _initialize() -> void:
	for hero: String in ["astra", "vex", "boros"]:
		var base: String = "res://assets/characters/" + hero + "/"
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + "manifest.json"))
		var frames := SpriteFrames.new()
		frames.remove_animation(&"default")
		for clip: String in manifest.animations:
			var entry: Dictionary = manifest.animations[clip]
			for direction: String in manifest.directions:
				var key := StringName(clip + "_" + direction)
				frames.add_animation(key)
				frames.set_animation_speed(key, float(entry.fps))
				frames.set_animation_loop(key, bool(entry.loop))
				for path: String in entry.directions[direction]:
					var texture := load(base + path) as Texture2D
					if texture == null:
						push_error("ART_IMPORT missing texture: " + path)
						quit(1)
						return
					frames.add_frame(key, texture)
		frames.set_meta("directions", PackedStringArray(manifest.directions))
		frames.set_meta("cardinal", true)
		frames.set_meta("weapon", load(base + "weapon.png"))
		frames.set_meta("feet_anchor", Vector2(64,108))
		frames.set_meta("vfx_color",Color(manifest.visual_profile.vfx_color))
		frames.set_meta("weapon_count",int(manifest.visual_profile.weapon_count))
		if ResourceSaver.save(frames, base + "frames.tres") != OK:
			quit(1)
			return
	print("ART_IMPORT_OK heroes=3 clips=108")
	quit(0)
