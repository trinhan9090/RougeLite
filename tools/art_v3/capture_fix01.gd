extends SceneTree
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var im: Image=root.get_texture().get_image()
	im.resize(640,360,Image.INTERPOLATE_NEAREST)
	im.save_png("res://reports/visual_qa/v3_fix01/"+name+".png")
	im.resize(1280,720,Image.INTERPOLATE_NEAREST)
	im.save_png("res://reports/visual_qa/v3_fix01/"+name+"_2x.png")
func run() -> void:
	var game := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(game);game.set_physics_process(false);game.presentation.hide();game.audio.enabled=false
	game._arena.apply_layout(game._arena.definition,[])
	game.skills.sync_level(11);game.skills.set_mode(&"MANUAL")
	var near: EnemyActor=game.spawn_enemy();var far: EnemyActor=game.spawn_enemy()
	for enemy: EnemyActor in [near,far]:enemy.set_physics_process(false);enemy.health=Health.new(10000)
	game.skills.candidates=[far,near]
	for f in range(360):
		if f in [0,90,180]:
			Input.action_release(&"move_up");Input.action_release(&"move_down")
			game.player.position=Vector2.ZERO
			near.position=Vector2(150,0);far.position=Vector2(280,60)
		if f==0:Input.action_press(&"move_up")
		if f==90:Input.action_press(&"move_down")
		if f==60:await shot("north_run")
		if f==150:await shot("south_run")
		if f==185:
			game.player.facing=Vector2.LEFT
			game.skills.request_cast(3,Vector2.LEFT*350)
		if f==194:await shot("l_nearest_behind_facing")
		if f==210:game._basic.step(0,[near],game.combat)
		if f==211:await shot("basic_hand_origin")
		if f==240:
			game.player.facing=Vector2.RIGHT
			game.skills.request_cast(4,Vector2.RIGHT*600)
		if f==242:await shot("beam_hand_origin")
		if f==280:
			game.combat.clear_transients();game.visual_factory.clear()
			near.position=Vector2(800,0);far.position=Vector2(900,0)
			game.skills.candidates=[near,far];game.player.facing=Vector2.LEFT
			game.skills.runtime_for(3).advance_cooldown(1000)
			game.skills.request_cast(3,Vector2.RIGHT*600)
			game._camera.offset=Vector2(-120,0)
		if f==290:await shot("l_no_enemy_max_range")
		await process_frame
	game.free();print("RESULT fix01 actual gameplay capture failures=0");quit()
