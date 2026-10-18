extends SceneTree
var checks:int=0
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func shot(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	var im:Image=root.get_texture().get_image();im.resize(640,360,Image.INTERPOLATE_NEAREST)
	im.save_png("res://reports/visual_qa/v3_fix03/"+label+".png")
	im.resize(1280,720,Image.INTERPOLATE_NEAREST);im.save_png("res://reports/visual_qa/v3_fix03/"+label+"_2x.png")
func run()->void:
	for hero:String in ["vex","boros","astra"]:
		var game:CombatRunRoot=(load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate()
		game.loadout_id=StringName("loadout."+hero);root.add_child(game)
		game.set_physics_process(false);game.audio.enabled=false;game.presentation.hide()
		game._arena.apply_layout(game._arena.definition,[])
		Input.action_press(&"move_up")
		for f:int in range(25):await physics_frame
		check(game.player.facing==Vector2.UP,hero+" actual WASD faces north")
		check(game.player.sprite_visual.animation==&"run_north",hero+" actual north animation")
		await shot(hero+"_north")
		Input.action_release(&"move_up")
		for f:int in range(4):await physics_frame
		check(game.player.sprite_visual.animation==&"idle_north",hero+" preserves north after stop")
		await shot(hero+"_north_idle")
		Input.action_press(&"move_down")
		for f:int in range(25):await physics_frame
		check(game.player.sprite_visual.animation==&"run_south",hero+" distinct actual south animation")
		await shot(hero+"_south")
		Input.action_release(&"move_down")
		for f:int in range(4):await physics_frame
		await shot(hero+"_sword_carry")
		if hero in ["boros","astra"]:
			game.skills.sync_level(11);game.skills.set_mode(&"MANUAL")
			check(game.skills.request_cast(2,Vector2(100,0)),hero+" real shield accepted")
			for f:int in range(4):await physics_frame
			var shield:PixelVisualEffect
			for n:Node in game.visual_factory.get_children():
				if n is PixelVisualEffect and n.bound_shield!=null:shield=n
			check(shield!=null and shield._body_center_offset()==Vector2(0,-24),hero+" shield centered on body")
			game.player.position+=Vector2(37,19)
			for f:int in range(3):await physics_frame
			check(shield!=null and (shield.global_position+shield._body_center_offset()).is_equal_approx(game.player.global_position+Vector2(0,-24)),hero+" moving shield center follows exact body")
			var attacker:EnemyActor=game.spawn_enemy();attacker.set_physics_process(false)
			var incoming:=SkillRankDefinition.new();incoming.damage=1;incoming.behavior=SkillBehaviorDefinition.new();incoming.behavior.can_crit=false
			var blocked:DamageResult=game.combat.hit(attacker,game.player,incoming,game.combat.next_context(attacker,&"test.enemy_hit"))
			check(blocked.shield_damage>0,hero+" actual hit absorbed by shield")
			await process_frame
			var pulse:PixelVisualEffect
			for n:Node in game.visual_factory.get_children():
				if n is PixelVisualEffect and n.kind=="guard_hit":pulse=n
			check(pulse!=null and pulse._body_center_offset()==Vector2(0,-24) and pulse.follow.get_ref()==game.player,hero+" real shield-hit pulse centered and uses defender renderer")
			await shot(hero+"_shield_center")
			if hero=="boros":
				check(game.skills.request_cast(4,Vector2(100,0)),"real Titan accepted")
				for f:int in range(4):await physics_frame
				var aura:PixelVisualEffect
				for n:Node in game.visual_factory.get_children():
					if n is PixelVisualEffect and n.bound_buff==&"skill.boros.i":aura=n
				check(aura!=null and aura._body_center_offset()==Vector2(0,-30),"Titan aura follows enlarged body center")
				check(shield!=null and shield._body_center_offset()==Vector2(0,-30),"shield adapts to same Titan body center")
				await shot("boros_titan_center")
		if hero=="vex":
			game.skills.sync_level(11);game.skills.set_mode(&"MANUAL")
			game.player.facing=Vector2.RIGHT
			check(game.skills.request_cast(2,Vector2(100,0)),"real Vex Tactical Roll accepted")
			for f:int in range(4):await physics_frame
			check(game.player.motion_active,"actual motion active")
			await shot("vex_during_roll")
			for f:int in range(30):await physics_frame
			check(not game.player.motion_active,"actual roll completed")
			check(not String(game.player.sprite_visual.animation).begins_with("cast_k"),"roll pose released")
			var haste:PixelVisualEffect
			for n:Node in game.visual_factory.get_children():
				if n is PixelVisualEffect and n.bound_buff==&"skill.vex.k":haste=n
			check(haste!=null and haste.style=="roll","actual haste buff has separate renderer")
			check(game.visual_factory.trails==0,"roll creates no projectile trails")
			var old_motion:bool=false
			for n:Node in game.combat.get_children():
				if n is TimedCombatEffect and n.executor.kind=="dash":old_motion=true
			check(not old_motion,"no dash dust owner after motion")
			await shot("vex_after_roll")
			for f:int in range(200):await physics_frame
			check(not game.player.buffs.has(&"skill.vex.k"),"real haste expiry")
			var lingering:bool=false
			for n:Node in game.visual_factory.get_children():
				if n is PixelVisualEffect and n.bound_buff==&"skill.vex.k":lingering=true
			check(not lingering,"no VFX after actual haste expiry")
			await shot("vex_after_haste")
		game.free();await process_frame
	print("RESULT roster corrections checks=%d failures=%d"%[checks,failures]);quit(0 if failures==0 else 1)
