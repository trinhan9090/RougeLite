extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks += 1
	if value: print("PASS ",label)
	else:
		failures += 1
		printerr("FAIL ",label)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run_tests() -> void:
	var profile := load("res://content/characters/vex_loadout.tres") as CombatLoadoutDefinition
	var sprites := load("res://content/characters/vex_visual_frames.tres") as SpriteFrames
	check(sprites != null,"Vex profile has sprite frames")
	for animation in sprites.get_animation_names():
		for index in range(sprites.get_frame_count(animation)):
			var image: Image = sprites.get_frame_texture(animation,index).get_image()
			check(image.get_size() == Vector2i(64,64) and not image.is_invisible(),"nonempty64px frame %s/%d" % [animation,index])
	var player := (load("res://scenes/characters/player.tscn") as PackedScene).instantiate() as PlayerActor
	player.visual_frames = sprites
	player.position = Vector2(500,350)
	root.add_child(player)
	check(player.sprite_visual != null and player.rig == null,"sprite replaces geometry only")
	await frames(3)
	check(player.sprite_visual.animation == &"idle","idle animation")
	Input.action_press(&"move_right")
	await frames(10)
	check(player.sprite_visual.animation == &"run","WASD movement animates run")
	Input.action_release(&"move_right")
	await frames(3)
	player.attack_flash = .12
	await frames(2)
	check(player.sprite_visual.animation == &"attack","attack feedback animates sprite")
	player.sprite_visual.play_action(&"cast")
	await frames(2)
	check(player.sprite_visual.animation == &"cast","active skill presentation")
	player.motion_active = true
	await frames(2)
	check(player.sprite_visual.animation == &"dash","dash presentation")
	player.motion_active = false
	player.set_physics_process(false)
	player.facing = Vector2.LEFT
	player.sprite_visual.play_action(&"attack")
	await frames(2)
	check(player.sprite_visual.flip_h,"left facing mirrors sprite")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/vex-sprite.png")
	player.health.commit_resolved_hp(0)
	await frames(2)
	check(player.sprite_visual.animation == &"death","death presentation")
	player.queue_free()
	await process_frame
	print("RESULT Vex sprites checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
