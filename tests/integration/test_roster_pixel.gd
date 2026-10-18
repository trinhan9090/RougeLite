extends SceneTree
var checks:int=0
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run()->void:
	for hero:String in ["vex","boros"]:
		var game:CombatRunRoot=(load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate()
		game.loadout_id=StringName("loadout."+hero)
		root.add_child(game);game.set_physics_process(false);game.player.set_physics_process(false)
		game.audio.enabled=false;game._arena.apply_layout(game._arena.definition,[])
		game.skills.sync_level(11);game.skills.set_mode(&"MANUAL")
		var enemy:EnemyActor=game.spawn_enemy();enemy.position=Vector2(65,0);enemy.health=Health.new(100000);enemy.set_physics_process(false)
		game.skills.candidates=[enemy]
		await physics_frame;await physics_frame
		var events:Array[Dictionary]=[]
		game.combat.visual_event.connect(func(e:Dictionary)->void:events.append(e))
		for action:String in ["basic","j","k","l","i"]:
			check(game.visual_factory.renderers.get("skill."+hero+"."+action)=="pixel_v3",hero+action+" shared renderer")
		for slot:int in [1,2,3,4]:
			game.player.position=Vector2.ZERO;game.player.facing=Vector2.RIGHT
			check(game.skills.request_cast(slot,Vector2(65,0)),hero+" actual skill accepted "+str(slot))
			await process_frame;await process_frame
			if hero=="boros" and slot==2:
				var bound:bool=false
				for e:Node in game.visual_factory.get_children():
					if e is PixelVisualEffect and e.bound_shield!=null:bound=true
				check(bound,"Iron Resolve bound to real shield")
			if hero=="boros" and slot==4:
				var bound:bool=false
				for e:Node in game.visual_factory.get_children():
					if e is PixelVisualEffect and e.bound_buff==&"skill.boros.i":bound=true
				check(bound,"Titan aura bound to actual buff")
			if (hero=="vex" and slot==2) or (hero=="boros" and slot==3):
				var attached:bool=false
				for n:Node in game.combat.get_children():
					for e:Node in n.get_children():
						if e is PixelVisualEffect and e.kind=="dash":attached=true
				check(attached,"dash VFX child of actual motion executor")
			for f:int in range(30):await physics_frame
			game.combat.clear_transients();await process_frame
		var hp:float=enemy.health.current
		game._basic.step(0,[enemy],game.combat)
		for f:int in range(20):await physics_frame
		check(enemy.health.current<hp,hero+" actual basic damages torso")
		if hero=="vex":
			var shots:Dictionary={}
			game.combat.projectile_fired.connect(func(_a:Actor,id:StringName)->void:shots[id]=shots.get(id,0)+1)
			for slot:int in [1,4]:
				game.skills.runtime_for(slot).advance_cooldown(1000)
				game.skills.request_cast(slot,Vector2(100,0))
				for f:int in range(200):await physics_frame
			check(shots.get(&"skill.vex.j",0)==4,"Barrage shows exactly four real shots")
			check(shots.get(&"skill.vex.i",0)==18,"Storm shows exactly eighteen real shots")
		game.combat.clear_transients();game.visual_factory.clear();await process_frame
		check(game.visual_factory.trails==0,hero+" no orphan projectile trails")
		game.free();await process_frame
	print("RESULT roster pixel checks=%d failures=%d"%[checks,failures]);quit(0 if failures==0 else 1)
