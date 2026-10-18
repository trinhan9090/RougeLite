extends SceneTree
## Real-executor capture; fixture unlocks skills only inside ArtPreview.
var out: String = "res://reports/astra_vfx02/"
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func snapshot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	if picture.save_png(out+name+".png")!=OK: failures += 1
	picture.resize(picture.get_width()*2,picture.get_height()*2,Image.INTERPOLATE_NEAREST)
	picture.save_png(out+name+"_2x.png")
func release_keys() -> void:
	for key in [&"move_left",&"move_right",&"move_up",&"move_down"]: Input.action_release(key)
func run() -> void:
	root.gui_disable_input = true
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="): out = argument.trim_prefix("--out=")
	if OS.get_cmdline_user_args().has("--normal"):
		await normal_play()
		return
	var preview := ArtPreview.new()
	root.add_child(preview)
	var quick: bool = OS.get_cmdline_user_args().has("--quick")
	var section: int = 60 if quick else 300
	for frame in range(section*6):
		var stage: int = frame/section
		var local_frame: int = frame%section
		if local_frame==0:
			release_keys()
			preview.game.combat.clear_transients()
			preview.game.visual_factory.clear()
			preview.game.player.clear_temporary()
			preview.game.player.position = Vector2.ZERO
			preview.target.position = Vector2(180,0)
			preview.caption.text = "ASTRA VFX 02 | QA fixture | "+(["Basic","J - Radiant Snare","K - Prism Guard","L - Solar Field","I - Celestial Beam","Combined / runtime layers"][stage])
		if stage<5:
			if local_frame in [5,150]:
				if not preview.cast(stage): failures += 1
			if local_frame==10: await snapshot("astra_"+["basic","j","k","l","i"][stage])
			if stage==2 and local_frame>20 and local_frame<30: Input.action_press(&"move_down")
			if stage==2 and local_frame==30: release_keys()
		else:
			if local_frame==5: preview.cast(2)
			if local_frame==6: preview.cast(3)
			if local_frame==25: preview.cast(1)
			if local_frame==30: preview.cast(4)
			if local_frame==35: await snapshot("astra_combined")
		await process_frame
	release_keys()
	preview.free()
	print("RESULT Astra current-play capture failures=",failures)
	quit(1 if failures else 0)

func normal_play() -> void:
	var game := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(game)
	for frame in range(600):
		if game._offer.size()==3: game.request_upgrade(0)
		var target := Vector2.from_angle(frame/30.0*1.1)*230
		var direction: Vector2 = game._arena.navigation_direction(game.player.position,target)
		release_keys()
		if direction.x>.25: Input.action_press(&"move_right")
		if direction.x<-.25: Input.action_press(&"move_left")
		if direction.y>.25: Input.action_press(&"move_down")
		if direction.y<-.25: Input.action_press(&"move_up")
		if frame==400: await snapshot("astra_play")
		await process_frame
	release_keys()
	var alive: bool = game.state.alive
	print("RESULT current PLAY alive=%s seconds=%.2f level=%d (normal stats/progression; WASD bot only)" % [alive,game.state.elapsed_simulation_seconds,game.state.current_level])
	game.free()
	quit(0 if alive else 1)
