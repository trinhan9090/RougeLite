extends SceneTree
var checks: int = 0
var failures: int = 0
var fixture_actors: Array[Actor] = []
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks += 1
	if value: print("PASS ",label)
	else: failures += 1;printerr("FAIL ",label)
func wait_time(seconds: float) -> void:
	var time: float = 0
	while time < seconds:
		await physics_frame
		for actor in fixture_actors:
			if is_instance_valid(actor): actor.advance_effects(1.0/60)
		time += 1.0/60
func run_tests() -> void:
	var registry := root.get_node("ContentRegistry") as ContentRegistryService
	check(registry.validate_all().is_empty(),"all four hero content valid")
	var profile := registry.definition_copy(&"loadout.atyu") as CombatLoadoutDefinition
	check(profile != null and profile.active_skills.size()==4,"fourth hero complete kit")
	var owner := PlayerActor.new()
	owner.actor_id=1
	owner.stats_definition=profile.stats
	owner.cast_origin_offset=profile.cast_origin_offset
	owner.visual_frames=profile.art_frames
	root.add_child(owner)
	owner.set_physics_process(false)
	owner.stats.crit_chance=0
	var enemies: Array[Actor]=[]
	for i in range(3):
		var target := Actor.new()
		target.actor_id=i+2
		target.team=2
		target.stats_definition=ActorStatDefinition.new()
		target.stats_definition.max_hp=10000
		target.position=[Vector2(90,0),Vector2(-90,0),Vector2(90,10)][i]
		root.add_child(target)
		fixture_actors.append(target)
		target.stats.armor=0
		enemies.append(target)
	var combat := CombatService.new()
	combat.rng=RunRng.new(87).stream(&"combat")
	root.add_child(combat)
	combat.actor_provider=func() -> Array[Actor]: return [owner,enemies[0],enemies[1],enemies[2]]
	var controller := SkillController.new(1,profile.active_skills,profile.basic_attack)
	controller.bind(owner,combat)
	controller.candidates=enemies
	controller.set_mode(&"MANUAL")
	check(not controller.request_cast(1,Vector2.RIGHT*200),"locked skill refused")
	check(controller.sync_level(11)==[1,2,3,4],"unlock3/6/9/11 preserved")
	check(controller.runtime_for(1).has_capability(&"resize_area") and controller.runtime_for(4).has_capability(&"resize_area"),"real cone and beam resize capabilities")
	check(not controller.runtime_for(3).has_capability(&"spawn_projectile_pattern") and not controller.runtime_for(1).has_capability(&"repeat_cast"),"unsupported split and echo fail closed")
	check(controller.auto_step()==0,"manual does not autocast")
	await physics_frame
	owner.facing=Vector2.RIGHT
	check(controller.request_cast(1,Vector2.LEFT*200),"manual cone accepts facing ignoring cursor")
	check(enemies[0].health.current==10000,"cone windup before hit")
	await wait_time(.25)
	check(enemies[0].health.current==9945 and enemies[2].health.current==9945,"cone hits multiple in front exactly once")
	check(enemies[1].health.current==10000,"cone excludes rear")
	check(controller.request_cast(2,Vector2.LEFT*200),"manual seal selects facing cone")
	await wait_time(.3)
	check(enemies[0].statuses.movement_factor()==0 and enemies[1].statuses.movement_factor()==1,"control only facing target")
	await wait_time(1.5)
	check(enemies[0].statuses.movement_factor()==1,"root expires")
	controller.advance_cooldowns(30)
	enemies[0].is_boss=true
	check(controller.request_cast(2,Vector2.RIGHT*200),"boss seal cast")
	await wait_time(.25)
	check(enemies[0].statuses.stunned(),"boss gets existing stagger")
	await wait_time(.2)
	check(not enemies[0].statuses.stunned(),"boss stagger remains .15 not source long stun")
	var before: float = enemies[0].health.current
	check(controller.request_cast(3,Vector2.RIGHT*200),"companion accepted")
	controller.advance_cooldowns(30)
	check(not controller.request_cast(3,Vector2.RIGHT*200),"no duplicate companion")
	await wait_time(.5)
	check(enemies[0].health.current < before,"companion real damage through resolver")
	check(owner.has_meta("companion_runtime"),"companion runtime owned per actor")
	before=enemies[0].health.current
	enemies[0].position.y = -24 # plain Actor fixture has no torso Area2D
	check(controller.request_cast(4,Vector2.LEFT*200),"beam manual facing")
	await wait_time(.2)
	check(enemies[0].health.current==before,"beam .4 windup before hit")
	await wait_time(.3)
	check(is_equal_approx(before-enemies[0].health.current,200),"companion enhances beam160 to200")
	check(enemies[1].health.current==10000,"beam does not hit rear")
	enemies[0].position.y = 0
	var basic := AttackController.new(owner,profile.basic_attack)
	before=enemies[0].health.current
	check(basic.step(1,enemies,combat),"basic auto nearest")
	check(enemies[0].health.current==before-22,"basic exact damage")
	var actions: Array[StringName]=[]
	for i in range(3):
		owner.sprite_visual.play_action(&"attack")
		actions.append(owner.sprite_visual.animation)
	check(actions[0]!=actions[1] and actions[1]!=actions[2],"basic three source combo variants")
	owner.facing=Vector2.LEFT
	await process_frame
	await process_frame
	check(owner.sprite_visual.flip_h,"side view left mirrored")
	owner.facing=Vector2.RIGHT
	await process_frame
	check(not owner.sprite_visual.flip_h,"side view right restored")
	owner.facing=Vector2.LEFT
	await process_frame
	await process_frame
	owner.facing=Vector2.UP
	await process_frame
	await process_frame
	check(owner.sprite_visual.flip_h,"vertical movement retains horizontal facing art")
	var resource_rank: float=profile.active_skills[3].rank_scaling[0].damage
	check(resource_rank==160,"enhancement does not mutate Resource")
	await wait_time(7.2)
	check(not owner.has_meta("companion_runtime"),"companion eight second cleanup")
	var manager := AugmentManager.new()
	var expand := load("res://content/augments/mechanics/area_expand.tres") as AugmentDefinition
	check(manager.apply_bound(expand,controller.runtime_for(1)),"area expand binds cone")
	check(manager.apply_bound(expand,controller.runtime_for(4)),"area expand binds beam")
	check(not manager.apply_bound(expand,controller.runtime_for(3)),"area expand refuses companion")
	controller.augments=manager
	controller.advance_cooldowns(30)
	owner.facing=Vector2.RIGHT
	enemies[2].position=Vector2(150,0)
	before=enemies[2].health.current
	check(controller.request_cast(1,Vector2.RIGHT*200),"expanded cone casts")
	await wait_time(.25)
	check(enemies[2].health.current==before-55,"expanded cone actually reaches150 beyond base140")
	enemies[2].position=Vector2(120,-5.5)
	before=enemies[2].health.current
	check(controller.request_cast(4,Vector2.RIGHT*200),"expanded beam casts without companion")
	await wait_time(.5)
	check(enemies[2].health.current==before-160,"expanded beam hits18.5 offset beyond base17")
	check(profile.active_skills[0].rank_scaling[0].radius_px==140,"resize leaves source definition intact")
	enemies[2].position=Vector2(90,10)
	controller.advance_cooldowns(30)
	enemies[1].position=Vector2(-40,0)
	controller.set_mode(&"AUTO")
	before=enemies[1].health.current
	check(controller.request_cast(1),"Auto cone acquires nearest enemy")
	await wait_time(.25)
	check(enemies[1].health.current==before-55,"Auto cone damage follows target")
	controller.set_mode(&"MANUAL")
	owner.facing=Vector2.RIGHT
	controller.advance_cooldowns(30)
	var input := InputEventAction.new()
	input.action=&"active_1"
	input.pressed=true
	check(SkillInputRouter.handle(input,controller,Vector2.LEFT*1000),"existing mapped J input casts fourth hero")
	await wait_time(.25)
	controller.advance_cooldowns(30)
	check(controller.request_cast(3,Vector2.RIGHT*200),"companion resummon")
	check(controller.request_cast(4,Vector2.RIGHT*200),"beam accepted before death")
	before=enemies[0].health.current
	owner.health.commit_resolved_hp(0)
	await wait_time(.6)
	check(not owner.has_meta("companion_runtime"),"companion removed on owner death")
	check(enemies[0].health.current==before,"owner death cancels delayed beam and strikes")
	owner.queue_free()
	for enemy in enemies: enemy.queue_free()
	combat.queue_free()
	await process_frame
	var menu := (load("res://scenes/bootstrap/main.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	var slots := menu.find_child("CharacterSlots",true,false) as GridContainer
	check(slots.get_child_count()==20,"twenty avatar boxes")
	var locked: int=0
	for button: Button in slots.get_children():
		if button.disabled and button.text=="?": locked+=1
	check(locked==14,"fourteen disabled unknown characters after sixth hero")
	menu._show_page(&"CHARACTER")
	await process_frame
	await process_frame
	check(root.get_visible_rect().encloses(slots.get_global_rect()),"twenty-slot grid fits visible viewport")
	(slots.get_child(3) as Button).pressed.emit()
	check(menu._selected_loadout==&"loadout.astra" and menu._character_details[&"loadout.atyu"].visible,"avatar previews without selecting")
	(menu.find_child("SelectAtyu",true,false) as Button).pressed.emit()
	check(menu._selected_loadout==&"loadout.atyu","detail select Atyu")
	menu._start_run()
	await process_frame
	var run := current_scene as CombatRunRoot
	check(run != null and run.loadout_id==&"loadout.atyu" and run.player.sprite_visual!=null,"Atyu starts current playable run")
	if run!=null: run.queue_free()
	await process_frame
	print("RESULT atyu: checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
