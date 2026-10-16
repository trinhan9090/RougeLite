extends SceneTree
func _initialize() -> void:
	var base := "res://assets/sprites/characters/boros/boros_sprite_pack/"
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base+"metadata/boros_animations.json"))
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.set_meta("directions",PackedStringArray(data.direction_order))
	frames.set_meta("skill_actions",{"area":"ground_slam","shield":"iron_resolve","buff":"transform_start"})
	var aliases := {"attack":"basic_attack","dash":"charge_loop","cast":"ground_slam"}
	var animations: Dictionary = data.animations.duplicate()
	for alias: String in aliases: animations[alias] = data.animations[aliases[alias]]
	for animation: String in animations:
		var info: Dictionary = animations[animation]
		var file_action: String = aliases.get(animation,animation)
		for direction: String in data.direction_order:
			var texture := load("res://assets/sprites/characters/boros/cleaned/boros_%s_%s.png" % [file_action,direction]) as Texture2D
			if texture == null or texture.get_size() != Vector2(info.frames*128,128):
				push_error("Invalid Boros strip "+animation+direction)
				quit(1)
				return
			var id := StringName(animation+"_"+direction)
			frames.add_animation(id)
			frames.set_animation_speed(id,info.fps)
			frames.set_animation_loop(id,info.loop)
			var image: Image = texture.get_image()
			var valid_indices: Array[int] = []
			for index in range(info.frames):
				if not image.get_region(Rect2i(index*128,0,128,128)).is_invisible(): valid_indices.append(index)
			if valid_indices.is_empty():
				push_error("Entirely empty Boros strip "+String(id))
				quit(1)
				return
			for index in range(info.frames):
				var source_index: int = index
				if index not in valid_indices:
					source_index = valid_indices[0]
					for available in valid_indices:
						if available <= index: source_index = available
					print("HELD_EMPTY_FRAME ",id,"/",index," -> ",source_index)
				var frame := AtlasTexture.new()
				frame.atlas = texture
				frame.filter_clip = true
				frame.region = Rect2(source_index*128,0,128,128)
				frames.add_frame(id,frame)
	var error: Error = ResourceSaver.save(frames,"res://content/characters/boros_visual_frames.tres")
	print("BOROS_FRAMES_SAVED error=",error)
	quit(0 if error == OK else 1)
