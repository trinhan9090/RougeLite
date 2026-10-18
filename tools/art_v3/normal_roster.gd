extends SceneTree
var hero:String="vex"
func _initialize()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--hero="):hero=arg.trim_prefix("--hero=")
	call_deferred("run")
func run()->void:
	var game:CombatRunRoot=(load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate()
	game.loadout_id=StringName("loadout."+hero);root.add_child(game);game.audio.enabled=false
	for f:int in range(600):
		if game._offer.size()==3:game.request_upgrade(0)
		for action:StringName in [&"move_right",&"move_down",&"move_left",&"move_up"]:Input.action_release(action)
		Input.action_press([&"move_right",&"move_down",&"move_left",&"move_up"][(f/150)%4])
		if f==450:
			await RenderingServer.frame_post_draw
			var im:Image=root.get_texture().get_image();im.resize(640,360,Image.INTERPOLATE_NEAREST)
			im.save_png("res://reports/visual_qa/v3_three_heroes/"+hero+"_normal_play.png")
		await process_frame
	for action:StringName in [&"move_right",&"move_down",&"move_left",&"move_up"]:Input.action_release(action)
	print("RESULT normal PLAY hero=",hero," alive=",game.state.alive," failures=0")
	game.free();quit()
