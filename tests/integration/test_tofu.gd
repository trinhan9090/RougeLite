extends SceneTree
var checks: int=0
var failures: int=0
var owner: PlayerActor
var target: Actor
var extra: Actor
var actors: Array[Actor]=[]
var combat: CombatService
var controller: SkillController
var profile: CombatLoadoutDefinition
var events: Array[Dictionary]=[]
var visuals: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if value:print("PASS ",label)
	else:failures+=1;printerr("FAIL ",label)
func frames(count: int,follow: bool=false) -> void:
	for i in range(count):
		if follow:target.position=owner.position+Vector2(30,0)
		await physics_frame
		for actor in actors:
			if is_instance_valid(actor):actor.advance_effects(1.0/60)
	await process_frame
func damage(id: int) -> float:
	var value: float=0
	for event in events:
		if event.target==id:value+=event.damage
	return value
func make_target(id: int,point: Vector2) -> Actor:
	var actor:=Actor.new();actor.actor_id=id;actor.team=2;actor.stats_definition=ActorStatDefinition.new();actor.position=point
	root.add_child(actor);actor.stats.armor=0;actor.health=Health.new(100000);actors.append(actor);return actor
func prepare(rank: int=1) -> void:
	combat.clear_transients();await frames(2)
	owner.position=Vector2.ZERO;owner.record_attack_direction(Vector2.RIGHT);owner.clear_temporary();owner.set_meta("melee_combo_index",0)
	target.position=Vector2(70,0);extra.position=Vector2(2000,0)
	for actor in [target,extra]:actor.health=Health.new(100000);actor.statuses=StatusController.new();actor.is_boss=false;actor.mark_left=0
	controller=SkillController.new(1,profile.active_skills,profile.basic_attack);controller.bind(owner,combat);controller.augments=AugmentManager.new();controller.candidates=[target,extra];controller.sync_level(11);controller.set_mode(&"MANUAL")
	for slot in range(1,5):
		for i in range(mini(rank,controller.runtime_for(slot).definition.max_rank)-1):controller.upgrade_rank(slot)
	events.clear();visuals.clear()
func run() -> void:
	AudioServer.set_bus_mute(0,true) # keep100-command audio audit quiet; streams still execute
	var registry:=root.get_node("ContentRegistry") as ContentRegistryService
	check(registry.validate_all().is_empty(),"T07 registry validates seventh hero without changing class schema")
	profile=registry.definition_copy(&"loadout.tofu") as CombatLoadoutDefinition
	check(profile!=null and profile.display_name=="Tofu" and profile.stats.max_hp==200 and profile.stats.armor==10,"Tofu200HP215speed10armor data")
	check(profile.art_frames.get_animation_names().size()==44 and profile.art_frames.get_meta("side_view",false),"T06 actual11source body clips with honest horizontal aliases")
	var locked:=SkillController.new(1,profile.active_skills)
	check(locked.sync_level(2).is_empty() and locked.sync_level(3)==[1] and locked.sync_level(6)==[2] and locked.sync_level(9)==[3] and locked.sync_level(11)==[4],"T07 free unlock3/6/9/11")
	check(profile.active_skills.map(func(skill: SkillDefinition) -> int:return skill.max_rank)==[4,4,4,3],"T07 rank caps4/4/4/3")
	owner=PlayerActor.new();owner.actor_id=1;owner.stats_definition=profile.stats;owner.cast_origin_offset=profile.cast_origin_offset
	owner.collision_layer=1;owner.collision_mask=4
	var collider:=CollisionShape2D.new();var circle:=CircleShape2D.new();circle.radius=13;collider.shape=circle;owner.add_child(collider)
	root.add_child(owner);owner.set_physics_process(false);owner.stats.crit_chance=0;actors.append(owner)
	target=make_target(2,Vector2(70,0));extra=make_target(3,Vector2(2000,0))
	combat=CombatService.new();combat.rng=RunRng.new(20261018).stream(&"combat");root.add_child(combat);combat.actor_provider=func() -> Array[Actor]:return actors
	combat.resolver.events.damage_applied.connect(func(context: CombatContext,result: DamageResult) -> void:events.append({"target":result.target_id,"damage":result.mitigated_damage,"secondary":context.is_secondary,"root":context.root_cast_id}))
	combat.visual_event.connect(func(event: Dictionary) -> void:visuals.append(event))
	await prepare()
	var basic:=AttackController.new(owner,profile.basic_attack);basic.runtime=controller.runtime_for(0);basic.augments=controller.augments
	for expected in [10.0,25.0,55.0]:
		basic.cooldown_left=0;check(basic.step(0,[target,extra],combat),"T08 real melee combo accepts nearest target")
		check(damage(2)==expected,"basic10/15/30 rotate in actor runtime")
	check(damage(3)==0 and not combat.get_children().any(func(n: Node) -> bool:return n is CombatProjectile),"basic is melee and never fires a projectile")
	check(not basic.step(0,[target],combat),"basic respects0.55s attack interval")
	target.position=Vector2(111,0);basic.cooldown_left=0
	check(not basic.step(0,[target],combat),"T09 no basic beyond110px")
	await prepare()
	check(controller.request_cast(1,Vector2.LEFT*200),"J accepts Manual last attack direction, ignores cursor")
	await frames(45,true)
	check(damage(2)==90 and events.size()==6,"T12 J six15damage ticks, no physics-frame duplicates")
	check(owner.position.x>235 and not owner.motion_active,"J actual240px collision-aware dash completes")
	check(not controller.request_cast(1,Vector2.RIGHT),"J8s cooldown enforced")
	await prepare(4);target.is_boss=true
	controller.request_cast(1,Vector2.RIGHT);await frames(57,true)
	check(damage(2)==120 and events.size()==8,"J rank2+ exactly8ticks")
	check(target.mark_left>2 and target.mark_bonus==.12,"J rank4 final hit exposes12percent3s")
	check(not target.statuses.stunned() and target.position.distance_to(owner.position+Vector2(30,0))<2,"T10 boss never knocked back or stunned")
	await prepare()
	var wall:=StaticBody2D.new();wall.collision_layer=4;var shape:=CollisionShape2D.new();var box:=RectangleShape2D.new();box.size=Vector2(20,150);shape.shape=box;wall.add_child(shape);root.add_child(wall);wall.position=Vector2(60,0);await frames(2)
	controller.request_cast(1,Vector2.RIGHT);await frames(50)
	check(owner.position.x<38 and not owner.motion_active,"J stops at actual wall and releases movement")
	wall.queue_free();await frames(2)
	await prepare();target.position=Vector2(300,0)
	controller.request_cast(2,Vector2.LEFT);await frames(15)
	check(damage(2)==0,"K0.35s telegraph")
	await frames(10);check(damage(2)==40,"K40damage single slam at Manual facing endpoint")
	await frames(370)
	check(damage(2)==124,"T11 K12debris ticks at7damage over6s")
	var after: float=damage(2);await frames(45);check(damage(2)==after and combat.get_child_count()==0,"K field expires with no delayed damage")
	await prepare(4);target.position=Vector2(430,0)
	controller.request_cast(2,Vector2.RIGHT);await frames(25)
	check(damage(2)==40 and target.statuses.stunned(),"K rank2radius132 and rank4nonboss1s stun")
	await frames(380);check(damage(2)==172,"K rank3 burning ground adds48damage across3s")
	await prepare();controller.request_cast(3,Vector2.RIGHT);await frames(60)
	check(damage(2)==250,"L four source-pattern hits50/50/50/100")
	check(owner.position.x>0 and owner.position.x<target.position.x,"L step dash does not overshoot locked target")
	await prepare(4);controller.request_cast(3,Vector2.RIGHT);await frames(70)
	check(damage(2)==310 and target.statuses.movement_factor()<1,"L fifth60damage and final30percent slow")
	await prepare(4);target.health=Health.new(10);extra.position=Vector2(90,0)
	controller.request_cast(3,Vector2.RIGHT);await frames(70)
	check(damage(3)>0,"T13 rank4 chain retargets after target dies")
	await prepare(4);target.health=Health.new(10);extra.health=Health.new(10);extra.position=Vector2(190,0)
	var third: Actor=make_target(4,Vector2(280,0));third.health=Health.new(10)
	controller.request_cast(3,Vector2.RIGHT);await frames(55)
	var chain: MeleeSequenceRuntime
	for node in combat.get_children():
		if node is MeleeSequenceRuntime:chain=node
	check(chain!=null and chain.retargets==2,"T13 chain stops retargeting after two switches")
	actors.erase(third);third.queue_free();await frames(2)
	await prepare();controller.request_cast(4,Vector2.RIGHT);await frames(20)
	check(damage(2)==0 and owner.invulnerability_left>0,"I0.45s windup with brief invulnerability")
	await frames(12);check(damage(2)==180 and events.size()==1,"I150+30 single authoritative nuke packet")
	await prepare(3);target.is_boss=true;controller.request_cast(4,Vector2.RIGHT);await frames(32)
	check(is_equal_approx(damage(2),234) and not target.statuses.stunned(),"I rank2boss+30percent and bossCC immunity")
	check(controller.runtime_for(4).cooldown_remaining==24,"I rank3 cooldown24s")
	await prepare(3)
	var fleeing:=EnemyActor.new();fleeing.actor_id=8;fleeing.definition=EnemyDefinition.new();fleeing.definition.stats=ActorStatDefinition.new();fleeing.definition.stats.max_hp=100000;fleeing.position=Vector2(100,0);root.add_child(fleeing);fleeing.set_target(owner);actors.append(fleeing)
	controller.request_cast(4,Vector2.RIGHT);await frames(32)
	var fear_distance: float=fleeing.position.distance_to(owner.position)
	check(fleeing.has_meta("fear_motion") and not fleeing.is_physics_processing(),"I rank3 fear owns only nonboss local steering")
	await frames(12)
	check(fleeing.position.distance_to(owner.position)>fear_distance,"I rank3 actual fear moves nearby enemy away")
	await frames(65)
	check(fleeing.is_physics_processing() and not fleeing.has_meta("fear_motion"),"fear expiry restores normal enemy AI")
	actors.erase(fleeing);fleeing.queue_free();await frames(2)
	await prepare();controller.request_cast(4,Vector2.RIGHT)
	var stun:=StatusEffectDefinition.new();stun.kind="stun";stun.duration=.2;owner.statuses.apply(stun);await frames(3)
	check(damage(2)==0 and controller.runtime_for(4).cooldown_remaining==15 and not owner.has_meta("movement_lock_runtime"),"I interrupt before damage refunds50percent and clears movement")
	await prepare()
	for file in ["projectile_split","pierce","multishot","homing"]:
		var path: String="res://content/augments/mechanics/"+file+".tres"
		if not ResourceLoader.exists(path):continue
		var augment:=load(path) as AugmentDefinition
		for slot in range(5):check(not controller.augments.can_bind(augment,controller.runtime_for(slot)),"T14 %s rejected slot%d"%[file,slot])
	var echo:=load("res://content/augments/mechanics/echo_cast.tres") as AugmentDefinition
	check(controller.augments.apply_bound(echo,controller.runtime_for(0)),"Basic real Echo capability")
	basic=AttackController.new(owner,profile.basic_attack);basic.runtime=controller.runtime_for(0);basic.augments=controller.augments;basic.step(0,[target],combat);await frames(45)
	check(is_equal_approx(damage(2),13.5) and int(owner.get_meta("melee_combo_index"))==1,"basic Echo preserves chosen combo step and cannot echo itself")
	await prepare();controller.augments.apply_bound(echo,controller.runtime_for(1));controller.request_cast(1,Vector2.RIGHT);await frames(140,true)
	check(is_equal_approx(damage(2),121.5),"J Echo replays complete dash once, preserving per-tick damage scale")
	await prepare();controller.augments.apply_bound(echo,controller.runtime_for(3));controller.request_cast(3,Vector2.RIGHT);await frames(135)
	check(is_equal_approx(damage(2),337.5),"L shared Echo once at35percent")
	await prepare();controller.augments.apply_bound(echo,controller.runtime_for(2));target.position=Vector2(300,0);controller.request_cast(2,Vector2.RIGHT);await frames(400)
	check(is_equal_approx(damage(2),138),"K Echo repeats slam only, not whole debris field")
	check(not controller.augments.can_bind(echo,controller.runtime_for(4)),"I rejects Echo at capability layer")
	var area:=load("res://content/augments/mechanics/area_expand.tres") as AugmentDefinition
	check(controller.augments.can_bind(area,controller.runtime_for(2)) and not controller.augments.can_bind(area,controller.runtime_for(1)),"only K supports real Area Expansion")
	await prepare();controller.augments.apply_bound(area,controller.runtime_for(2));target.position=Vector2(420,0)
	controller.request_cast(2,Vector2.RIGHT);await frames(25)
	check(damage(2)==40,"T15 expanded K geometry hits120px from center outside110base")
	var radius_matches: bool=false
	for event in visuals:
		if event.kind=="melee_field":radius_matches=is_equal_approx(event.radius,123.2)
	check(radius_matches,"T15 actual field VFX boundary equals augmented collision radius")
	await prepare(4);target.is_boss=true;target.position=Vector2(300,0);controller.request_cast(2,Vector2.RIGHT);await frames(25)
	check(not target.statuses.stunned() and damage(2)==40,"T10 K does not knock up or stun boss")
	await prepare(4);target.is_boss=true;controller.request_cast(3,Vector2.RIGHT);await frames(70)
	check(is_equal_approx(target.statuses.movement_factor(),.85),"boss receives half of L slow strength")
	await prepare();target.position=Vector2(111,0)
	check(not controller.request_cast(4,Vector2.RIGHT) and controller.runtime_for(4).cooldown_remaining==0,"I cannot acquire beyond melee range or spend cooldown")
	var signatures: Array[String]=[]
	for repetition in range(2):
		await prepare();owner.stats.crit_chance=.5;combat.rng=RunRng.new(731).stream(&"combat")
		basic=AttackController.new(owner,profile.basic_attack)
		for i in range(20):basic.cooldown_left=0;basic.step(0,[target],combat)
		signatures.append(JSON.stringify(events.map(func(event: Dictionary) -> float:return event.damage)))
	check(signatures[0]==signatures[1],"T17 seeded melee critical sequence is deterministic")
	owner.stats.crit_chance=0
	await prepare();controller.set_mode(&"AUTO");target.position=Vector2(250,0);extra.position=Vector2(270,0)
	check(controller.request_cast(2),"Auto K accepts densest reachable cluster")
	var field:=combat.get_children().filter(func(n: Node) -> bool:return n is MeleeSequenceRuntime)[0] as MeleeSequenceRuntime
	check(field.center==target.position,"Auto cluster ties stable by actor order")
	combat.clear_transients();await frames(2)
	check(not owner.motion_active and not owner.has_meta("movement_lock_runtime") and combat.get_child_count()==0,"T16 map/reset removes fields/motion and queued Echo")
	for actor in actors:actor.queue_free()
	actors.clear();combat.queue_free();await process_frame
	await scene_checks()
	print("RESULT tofu: checks=%d failures=%d"%[checks,failures]);quit(0 if failures==0 else 1)
func scene_checks() -> void:
	var settings:=root.get_node("AppSettings") as SettingsService;var old: StringName=settings.mode();settings.set_mode(&"MANUAL")
	var game: TrainingRun=(load("res://scenes/run/training_run.tscn") as PackedScene).instantiate();game.loadout_id=&"loadout.tofu";game.basic_auto=false;root.add_child(game)
	check(game.player.sprite_visual!=null and game.player.get_node_or_null("MeleeEffects")!=null,"actual Tofu source body and VFX bind in Training")
	game.boss.position=game.player.position+Vector2(65,0)
	for i in range(100):game._basic.cooldown_left=0;game.request_basic_attack()
	var voice_count: int=0
	for cue: String in game.player.action_audio.profile:
		for item: Dictionary in game.player.action_audio.profile[cue]:
			if item.get("channel","")=="voice":voice_count+=1
	check(voice_count==0 and game.player.action_audio.dispatched.get("basic",0)+game.player.action_audio.dispatched.get("combo_1",0)+game.player.action_audio.dispatched.get("combo_2",0)==100,"T19 100actual basic commands produce100nonvoice weapon cues")
	check(game.player.action_audio.profile.cast_j.size()==1 and game.player.action_audio.profile.cast_i.size()==1,"T19 each skill uses one honest fallback cue; source voices remain unverified")
	game.reset_training();await frames(3)
	game.skills.request_cast(2,game.player.position+Vector2.RIGHT*300);await frames(25)
	var renderer:=game.player.get_node("MeleeEffects") as MeleeActorEffects
	check(renderer.shown.get("slam",0)>0 and renderer.shown.get("debris",0)==5,"real source slam/debris follow actual field timing")
	game.reset_training();await frames(3)
	check(game.combat.get_child_count()==0 and not game.player.has_meta("movement_lock_runtime"),"Training reset clears Tofu transients")
	game.queue_free();await process_frame
	var menu: Node=(load("res://scenes/bootstrap/main.tscn") as PackedScene).instantiate();root.add_child(menu);await process_frame;await process_frame
	var grid:=menu.find_child("CharacterSlots",true,false) as GridContainer;var unavailable: int=0
	for child in grid.get_children():
		if child is Button and child.disabled:unavailable+=1
	check(grid.get_child_count()==20 and unavailable==13,"seven available avatars and13unknown slots")
	menu._select_character(&"loadout.tofu");menu._start_run();await process_frame
	var normal:=current_scene as CombatRunRoot
	check(normal!=null and normal.loadout_id==&"loadout.tofu","seventh avatar starts actual PLAY")
	normal.set_physics_process(false);normal.skills.sync_level(11)
	var enemy: EnemyActor=normal.spawn_enemy()
	check(enemy!=null and enemy.global_position.distance_to(normal.player.global_position)>=550,"Tofu PLAY preserves550safe spawn")
	if enemy!=null:
		enemy.set_physics_process(false);enemy.position=normal.player.position+Vector2(70,0);enemy.health=TrainingHealth.new(100000);normal.skills.candidates=[enemy]
	var key:=InputEventKey.new();key.physical_keycode=settings.binding_for(&"active_1");key.pressed=true;Input.parse_input_event(key);await frames(50)
	check(normal.skills.runtime_for(1).cooldown_remaining>0,"current remappable J input works in PLAY")
	normal.combat.clear_transients();await frames(3)
	normal.state.current_level=10;normal.state.current_xp=0;normal.gate.request(10)
	for i in range(20):
		normal._spawn_boss()
		if normal.boss!=null:break
	check(normal.boss!=null,"level-gated real boss spawns for seventh hero")
	var maps: int=normal.maps_visited
	if normal.boss!=null:
		var lethal:=SkillRankDefinition.new();lethal.damage=1000000;lethal.damage_type="TRUE";normal.combat.hit(normal.player,normal.boss,lethal,normal.combat.next_context(normal.player,&"test.tofu_finish"));await frames(3)
		check(normal.maps_visited==maps+1,"real boss victory transitions map")
	normal.queue_free();await process_frame;settings.set_mode(old)
