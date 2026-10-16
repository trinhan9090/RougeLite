extends SceneTree
var failed: int = 0
func _initialize() -> void: call_deferred("run")
func ticks(count: int) -> void:
	for index in range(count): await physics_frame
func capture(path: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png("res://screenshots/art/"+path+".png")
	if result != OK: failed += 1
func run() -> void:
	var preview := ArtPreview.new()
	root.add_child(preview)
	for hero: String in ["astra","vex","boros"]:
		preview.select_hero(hero)
		await ticks(3)
		for slot in range(5):
			preview.game.combat.clear_transients()
			preview.game.visual_factory.clear()
			preview.game.player.clear_temporary()
			preview.game.player.motion_active = false
			await process_frame
			preview.game.player.position = Vector2.ZERO
			if not preview.cast(slot):
				printerr("PREVIEW_CAST_FAILED ",hero," ",slot)
				failed += 1
			await ticks(2 if slot in [0,1,4] else 5)
			await capture(hero+"_"+["basic","j","k","l","i"][slot])
			await ticks(90)
		preview.game.combat.clear_transients()
		preview.game.visual_factory.clear()
		preview.game.player.clear_temporary()
		await process_frame
		for frame in range(8):
			preview.game.player.velocity = Vector2.RIGHT*100
			preview.game.player.sprite_visual.play_action(&"run")
			preview.game.player.sprite_visual.set_frame_and_progress(frame,0)
			await capture(hero+"_anim_%02d" % frame)
		preview.game.player.velocity = Vector2.ZERO
	for theme: String in ["enchanted_forest","ruined_temple","volcanic_arena"]:
		var definition := load("res://content/maps/"+theme+".tres") as MapDefinition
		for seed_value in [1,42,999]:
			preview.game._arena.apply_layout(definition,MapLayoutGenerator.generate(definition,RunRng.new(seed_value).stream(&"obstacles")))
			preview.game._camera.zoom = Vector2.ONE*.45
			preview.caption.text = theme+" · seed "+str(seed_value)+" · Actual collision geometry"
			await ticks(3)
			await capture(theme+"_"+str(seed_value))
	preview.free()
	await process_frame
	print("RESULT art preview captures=48 failures=%d renderer=%s" % [failed,DisplayServer.get_name()])
	quit(0 if failed==0 else 1)
