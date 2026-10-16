extends SceneTree
func _initialize() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.set_meta("left_facing_animations",PackedStringArray(["idle"]))
	var sheet := load("res://assets/sprites/characters/vex/vex/spritesheet.png") as Texture2D
	for entry: Array in [["idle",4,6,8,true],["run",0,8,12,true],["attack",3,7,28,false],["dash",2,7,20,true],["cast",5,4,16,false],["death",1,8,12,false]]:
		var id := StringName(entry[0])
		frames.add_animation(id)
		frames.set_animation_speed(id,entry[3])
		frames.set_animation_loop(id,entry[4])
		for index in range(entry[2]):
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.filter_clip = true
			frame.region = Rect2(index*64,entry[1]*64,64,64)
			frames.add_frame(id,frame)
	var error: Error = ResourceSaver.save(frames,"res://content/characters/vex_visual_frames.tres")
	print("SPRITE_FRAMES_SAVED error=",error)
	quit(0 if error == OK else 1)
