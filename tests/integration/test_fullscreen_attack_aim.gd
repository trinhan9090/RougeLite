extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks+=1
	if value: print("PASS ",label)
	else: failures+=1;printerr("FAIL ",label)
func run_tests() -> void:
	check(ProjectSettings.get_setting("display/window/stretch/scale_mode")=="fractional","fractional scale removes integer black frame")
	check(ProjectSettings.get_setting("display/window/stretch/aspect")=="expand","expand aspect fills irregular window")
	check(ProjectSettings.get_setting("display/window/size/mode")==3,"fullscreen configured by default")
	check(ProjectSettings.get_setting("display/window/size/viewport_width")==1920 and ProjectSettings.get_setting("display/window/size/viewport_height")==1080,"native render viewport1920x1080")
	if DisplayServer.get_name() != "headless":
		check(root.mode==Window.MODE_FULLSCREEN,"actual startup fullscreen")
		check(root.get_texture().get_size()==Vector2(1920,1080),"actual native render surface1920x1080 before resize")
		root.mode=Window.MODE_WINDOWED
	var menu := (load("res://scenes/bootstrap/main.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for resolution: Vector2i in [Vector2i(1280,720),Vector2i(1918,1052),Vector2i(1366,768)]:
		root.size=resolution
		for i in range(4): await process_frame
		check(menu.size.is_equal_approx(root.get_visible_rect().size) and menu.scale==Vector2.ONE,"native UI covers viewport "+str(resolution))
		menu._show_page(&"CHARACTER")
		for i in range(3): await process_frame
		var grid := menu.find_child("CharacterSlots",true,false) as GridContainer
		check(root.get_visible_rect().encloses(grid.get_global_rect()),"20-slot grid visible "+str(resolution))
	menu.queue_free()
	await process_frame
	var registry := root.get_node("ContentRegistry") as ContentRegistryService
	for hero: String in ["astra","vex","boros","atyu"]:
		var profile := registry.definition_copy(StringName("loadout."+hero)) as CombatLoadoutDefinition
		var owner := PlayerActor.new()
		owner.actor_id=1
		owner.stats_definition=profile.stats
		owner.visual_frames=profile.art_frames
		owner.cast_origin_offset=profile.cast_origin_offset
		root.add_child(owner)
		owner.set_physics_process(false)
		owner.manual_aim=true
		owner.stats.crit_chance=0
		var target := Actor.new()
		target.actor_id=2;target.team=2
		target.stats_definition=ActorStatDefinition.new()
		target.position=Vector2(-60,0)
		root.add_child(target)
		target.stats.armor=0
		var combat := CombatService.new()
		combat.rng=RunRng.new(17).stream(&"combat")
		combat.actor_provider=func() -> Array[Actor]: return [owner,target]
		root.add_child(combat)
		var basic := AttackController.new(owner,profile.basic_attack)
		check(basic.step(1,[target],combat),hero+" actual basic accepted")
		var expected: Vector2 = owner.global_position.direction_to(target.global_position)
		if profile.basic_attack.executor.strategy=="projectile": expected=combat.cast_origin(owner).direction_to(TargetingService.intercept_point(combat.cast_origin(owner),target,profile.basic_attack.rank_scaling[0].projectile_speed))
		check(owner.attack_direction.is_equal_approx(expected),hero+" records actual basic direction")
		owner.facing=Vector2.DOWN
		owner.set_physics_process(true)
		Input.action_press(&"move_down")
		for i in range(3): await physics_frame
		Input.action_release(&"move_down")
		owner.set_physics_process(false)
		check(owner.attack_direction.is_equal_approx(expected),hero+" movement cannot rotate aim")
		await process_frame
		check(owner.aim_indicator.visible and owner.aim_indicator.position.y>0 and owner.aim_indicator.z_index<0,hero+" indicator under feet behind art")
		owner.record_attack_direction(Vector2.ZERO)
		owner.record_attack_direction(Vector2(INF,0))
		check(owner.attack_direction.is_equal_approx(expected),hero+" invalid directions ignored")
		var controller := SkillController.new(1,profile.active_skills)
		controller.bind(owner,combat)
		controller.candidates=[target]
		controller.set_mode(&"MANUAL")
		check(not controller.request_cast(1,Vector2.RIGHT*999) and owner.attack_direction.is_equal_approx(expected),hero+" rejected cast preserves aim")
		controller.sync_level(11)
		combat.clear_transients()
		await process_frame
		check(controller.request_cast(1,Vector2.RIGHT*999),hero+" Manual J accepted")
		if hero in ["astra","vex"]:
			var shot := combat.get_child(0) as CombatProjectile
			var executor := profile.active_skills[0].executor as EffectExecutorDefinition
			var rank: SkillRankDefinition = profile.active_skills[0].rank_scaling[0]
			var lane: Vector2 = expected.rotated(-(rank.projectile_count-1)*.5*executor.spread_radians)
			check(shot!=null and shot._direction.is_equal_approx(lane),hero+" projectile pattern matches last attack instead of movement")
		check(owner.attack_direction.is_equal_approx(expected),hero+" directed skill maintains Manual direction")
		owner.manual_aim=false
		await process_frame
		await process_frame
		check(not owner.aim_indicator.visible,hero+" Auto hides ground indicator")
		owner.queue_free();target.queue_free();combat.queue_free()
		await process_frame
	var game := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(game)
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	await process_frame
	await process_frame
	check(game.presentation.scale==Vector2.ONE and game.presentation.size.is_equal_approx(root.get_visible_rect().size),"native run HUD and modal cover fill viewport")
	check(game._camera.zoom==Vector2(2,2),"pixel-art camera remains readable with native render")
	var spawned: EnemyActor
	for attempt in range(10):
		spawned=game.spawn_enemy()
		if spawned!=null: break
	check(spawned!=null,"native viewport can spawn reachable offscreen enemies")
	if spawned!=null:
		var world_size: Vector2 = root.get_visible_rect().size/game._camera.zoom
		var world_rect := Rect2(game._camera.get_screen_center_position()-world_size*.5,world_size)
		check(not world_rect.grow(20).has_point(spawned.position) and spawned.position.distance_to(game.player.position)>=550,"spawn uses camera world extent and unchanged safety550")
	game.queue_free()
	await process_frame
	print("RESULT fullscreen attack aim: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
