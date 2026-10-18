extends SceneTree
var hero:String="vex"
var advanced:bool=false
func _initialize()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--hero="):hero=arg.trim_prefix("--hero=")
		if arg=="--advanced":advanced=true
	call_deferred("run")
func shot(label:String)->void:
	await RenderingServer.frame_post_draw
	var im:Image=root.get_texture().get_image();im.resize(640,360,Image.INTERPOLATE_NEAREST)
	var prefix:String=hero+("_advanced" if advanced else "")
	im.save_png("res://reports/visual_qa/v3_three_heroes/"+prefix+"_"+label+".png")
	im.resize(1280,720,Image.INTERPOLATE_NEAREST);im.save_png("res://reports/visual_qa/v3_three_heroes/"+prefix+"_"+label+"_2x.png")
func run()->void:
	var game:CombatRunRoot=(load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate()
	game.loadout_id=StringName("loadout."+hero);root.add_child(game)
	game.set_physics_process(false);game.audio.enabled=false;game.presentation.hide()
	game._arena.apply_layout(game._arena.definition,[]);game.skills.sync_level(11);game.skills.set_mode(&"MANUAL")
	if advanced:
		for slot:int in range(1,5):
			while game.skills.runtime_for(slot).upgrade_rank():continue
	var enemies:Array[Actor]=[]
	for n:int in range(6):
		var e:EnemyActor=game.spawn_enemy();e.set_physics_process(false);e.health=Health.new(100000);enemies.append(e)
	game.skills.candidates=enemies
	for f:int in range(600):
		if f%100==0:
			game.combat.clear_transients();game.player.position=Vector2.ZERO;game.player.facing=Vector2.RIGHT
			for n:int in range(enemies.size()):enemies[n].position=Vector2(60+n*35,(n%3-1)*22)
			for slot:int in range(1,5):game.skills.runtime_for(slot).advance_cooldown(1000)
		if f==5:Input.action_press(&"move_up")
		if f==45:await shot("north")
		if f==50:Input.action_release(&"move_up");game.player.position=Vector2.ZERO
		if f==60:game._basic.step(0,enemies,game.combat)
		if f==63:await shot("basic")
		if f in [105,205,305,405]:game.skills.request_cast(f/100,Vector2(160,0))
		if f in [110,210,310,410]:await shot("skill_"+str(f/100))
		if f==505:Input.action_press(&"move_down")
		if f==545:await shot("south")
		if f==550:Input.action_release(&"move_down")
		await process_frame
	game.free();print("RESULT roster capture ",hero," failures=0");quit()
