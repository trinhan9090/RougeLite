extends SceneTree
var checks: int=0
var failures: int=0
var profile: CombatLoadoutDefinition
var owner: Actor
var target: Actor
var extra: Actor
var combat: CombatService
var controller: SkillController
var events: Array[Dictionary]=[]
var visuals: Array[Dictionary]=[]
var actors: Array[Actor]=[]
func _initialize() -> void:call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks+=1
	if value:print("PASS ",label)
	else:failures+=1;printerr("FAIL ",label)
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		for actor in actors:
			if is_instance_valid(actor):actor.advance_effects(1.0/60)
	await process_frame
func make_actor(id: int,team: int,point: Vector2) -> Actor:
	var actor:=Actor.new();actor.actor_id=id;actor.team=team;actor.position=point;actor.stats_definition=ActorStatDefinition.new()
	actor.collision_layer=1 if team==1 else 2;actor.collision_mask=4
	var collider:=CollisionShape2D.new();var circle:=CircleShape2D.new();circle.radius=16;collider.shape=circle;actor.add_child(collider)
	root.add_child(actor);actor.stats.armor=0;actor.stats.crit_chance=0;actor.health=Health.new(100000)
	actors.append(actor);return actor
func prepare(rank: int=1) -> void:
	combat.clear_transients();await frames(2)
	owner.clear_temporary();target.clear_temporary();extra.clear_temporary()
	owner.position=Vector2.ZERO;target.position=Vector2(100,0);extra.position=Vector2(1000,0)
	target.is_boss=false;target.health=Health.new(100000);extra.health=Health.new(100000)
	controller=SkillController.new(owner.actor_id,profile.active_skills,profile.basic_attack);controller.bind(owner,combat);controller.augments=AugmentManager.new();controller.candidates=[target,extra];controller.sync_level(11);controller.set_mode(&"MANUAL")
	for slot in range(1,5):
		for i in range(mini(rank,controller.runtime_for(slot).definition.max_rank)-1):controller.upgrade_rank(slot)
	events.clear();visuals.clear()
func sum_damage(id: int) -> float:
	var total: float=0
	for event in events:
		if event.target==id:total+=event.damage
	return total
func count_kind(kind: String) -> int:
	var total: int=0
	for event in visuals:
		if event.kind==kind:total+=1
	return total
func run_tests() -> void:
	var registry:=root.get_node("ContentRegistry") as ContentRegistryService
	check(registry.validate_all().is_empty(),"T26 all content validates with sixth hero")
	profile=registry.definition_copy(&"loadout.graveshade") as CombatLoadoutDefinition
	check(profile!=null and profile.class_id==&"adc" and profile.stats.max_hp==115 and profile.stats.move_speed==210,"T02 data ADC115HP210speed")
	check(profile.art_frames.get_meta("side_view",false) and profile.art_frames.get_frame_count(&"idle_east")==7,"T06 T07 actual source side-view body, no invented rear")
	check(profile.art_frames.get_frame_texture(&"idle_north",0)==profile.art_frames.get_frame_texture(&"idle_south",0),"T07 vertical controller aliases same original side artwork")
	var locked:=SkillController.new(1,profile.active_skills,profile.basic_attack)
	check(locked.sync_level(2).is_empty() and locked.sync_level(3)==[1] and locked.sync_level(6)==[2] and locked.sync_level(9)==[3] and locked.sync_level(11)==[4],"T19 skills unlock3/6/9/11")
	check(profile.active_skills.map(func(skill: SkillDefinition) -> int:return skill.max_rank)==[4,4,4,3],"T20 rank caps4/4/4/3")
	owner=make_actor(1,1,Vector2.ZERO);target=make_actor(2,2,Vector2(100,0));extra=make_actor(3,2,Vector2(1000,0))
	combat=CombatService.new();combat.rng=RunRng.new(20261017).stream(&"combat");root.add_child(combat);combat.actor_provider=func() -> Array[Actor]:return actors
	combat.resolver.events.damage_applied.connect(func(context: CombatContext,result: DamageResult) -> void:events.append({"target":result.target_id,"damage":result.mitigated_damage,"skill":context.source_skill_id,"depth":context.generation_depth}))
	combat.visual_event.connect(func(event: Dictionary) -> void:visuals.append(event))
	await prepare()
	var basic:=AttackController.new(owner,profile.basic_attack)
	check(basic.step(1,[target,extra],combat),"T08 nearest basic accepted")
	await frames(20)
	check(sum_damage(2)==15 and sum_damage(3)==0,"T08 basic15 actual hit nearest only")
	await prepare();target.position=Vector2(500,0)
	basic=AttackController.new(owner,profile.basic_attack)
	check(not basic.step(1,[target,extra],combat),"T09 no basic outside340")
	await prepare()
	check(controller.request_cast(1,Vector2.RIGHT*400),"T10 J accepted")
	await frames(50)
	check(count_kind("fire_round")==5,"T10 J exactly5 native round events")
	var angles: Array[float]=[]
	for event in visuals:
		if event.kind=="fire_round":angles.append((event.direction as Vector2).angle())
	check(is_equal_approx(rad_to_deg(angles.back()-angles.front()),22),"T10 J native spread22degrees")
	check(sum_damage(2)<=60 and sum_damage(2)>0,"T10 J5hit cap actual projectiles")
	var base_j_damage: float=sum_damage(2)
	check(not controller.request_cast(1,Vector2.RIGHT),"T16 J cooldown enforced")
	await prepare(4)
	check(controller.request_cast(1,Vector2.RIGHT*400),"J rank4 accepted")
	await frames(65)
	check(count_kind("fire_round")==7 and sum_damage(2)<=65,"J7rounds max5target hits with exposed modifier")
	check(target.marked_by==1 and target.mark_left>0 and is_equal_approx(target.mark_bonus,.12),"J rank4 EXPOSED after3confirmed hits")
	await prepare()
	check(controller.request_cast(2,Vector2(100,0)),"T11 K accepted")
	await frames(35);check(sum_damage(2)==0,"K .7s fuse telegraph before damage")
	await frames(10);check(sum_damage(2)==80,"T11 K80damage once per target")
	await frames(45);check(sum_damage(2)==80,"T11 no duplicate explosion hits")
	await prepare()
	var wall:=StaticBody2D.new();wall.collision_layer=4;wall.position=Vector2(50,0)
	var wall_collider:=CollisionShape2D.new();var rectangle:=RectangleShape2D.new();rectangle.size=Vector2(8,200);wall_collider.shape=rectangle;wall.add_child(wall_collider);root.add_child(wall)
	await frames(2)
	controller.request_cast(2,Vector2(100,0));await frames(50)
	check(sum_damage(2)==0 and count_kind("explosion")==1,"T12 grenade clamps to wall and cannot damage through obstacle")
	wall.queue_free();await frames(2)
	await prepare(4)
	controller.request_cast(2,Vector2(100,0));await frames(240)
	check(count_kind("burning_ground")==1 and count_kind("explosion")==3 and count_kind("burn_tick")==3,"K rank4 two secondary blasts and3burn ticks")
	check(sum_damage(2)>=128 and sum_damage(2)<=208,"K bounded80+48burn+up to80secondary")
	await prepare();target.is_boss=true
	controller.request_cast(2,Vector2(100,0));await frames(50)
	check(target.global_position==Vector2(100,0) and sum_damage(2)==80,"boss takes grenade damage without knockback")
	await prepare()
	check(controller.request_cast(3,Vector2.RIGHT*100),"T13 L accepted")
	await frames(2)
	var mines: Array[TacticalMine]=[]
	for child in combat.get_children():
		if child is TacticalMine:mines.append(child as TacticalMine)
	check(mines.size()==2,"T13 rank1two mines")
	check(not mines[0].armed,"L mines not armed before.5s")
	target.position=mines[0].global_position
	await frames(31)
	check(count_kind("mine_explosion")>0,"L real proximity trigger after arming")
	await prepare();target.is_boss=true
	controller.request_cast(3,Vector2.RIGHT);await frames(2)
	for child in combat.get_children():
		if child is TacticalMine:target.position=(child as TacticalMine).global_position;break
	await frames(33)
	check(is_equal_approx(sum_damage(2),45.5),"mine boss damage exactly65x.7")
	await prepare(4);target.position=Vector2(1000,0)
	for i in range(3):controller.runtime_for(3).advance_cooldown(100);controller.request_cast(3,Vector2.RIGHT);await frames(2)
	mines.clear()
	for child in combat.get_children():
		if child is TacticalMine and not child.is_queued_for_deletion():mines.append(child as TacticalMine)
	check(mines.size()==6,"T13 mine owner cap6 evicts oldest without damage")
	await frames(32)
	var first: TacticalMine
	for mine in mines:
		if mine.chain_leader:first=mine;break
	first.detonate();await frames(2)
	check(count_kind("mine_explosion")>=2 and count_kind("mine_explosion")<=6,"T15 bounded chain detonates neighbor at mostonce")
	await prepare();target.position=Vector2(1000,0)
	controller.request_cast(3,Vector2.RIGHT);await frames(2)
	for child in combat.get_children():
		if child is TacticalMine:(child as TacticalMine).age=11.99
	await frames(3)
	check(not combat.get_children().any(func(node: Node) -> bool:return node is TacticalMine),"T14 expiry removes mine with no explosion")
	await prepare()
	check(controller.request_cast(4,Vector2.RIGHT*650),"T16 I accepted")
	await frames(20);check(count_kind("rocket_spawn")==0,"I .45s windup before rocket")
	await frames(30)
	check(count_kind("rocket_spawn")==1 and sum_damage(2)==260,"T16 I one actual rocket then260AOE")
	check(not controller.request_cast(4,Vector2.RIGHT),"T16 I28s cooldown enforced")
	await prepare(3)
	controller.request_cast(4,Vector2.RIGHT*650);await frames(160)
	check(count_kind("rocket_spawn")==3,"T16 rank2+ three actual rockets")
	check(count_kind("cluster")==3,"rank3exactly3cluster pulses")
	check(sum_damage(2)<=689,"T17 at most2rocket explosions plus3boundedcluster ticks")
	await prepare()
	var split:=load("res://content/augments/mechanics/projectile_split.tres") as AugmentDefinition
	check(controller.augments.apply_bound(split,controller.runtime_for(1)),"T21 shared Split binds J")
	check(not controller.augments.apply_bound(split,controller.runtime_for(3)),"T21 Split rejected mines")
	controller.request_cast(1,Vector2.RIGHT*400);await frames(50)
	check(count_kind("fire_round")==5 and combat.get_child_count()<100,"T23 shared split stays bounded")
	var echo:=load("res://content/augments/mechanics/echo_cast.tres") as AugmentDefinition
	for slot in range(1,5):check(controller.augments.apply_bound(echo,controller.runtime_for(slot)),"T21 shared Echo binds active%d"%slot)
	await prepare()
	check(controller.augments.apply_bound(echo,controller.runtime_for(1)),"J Echo test binds")
	controller.request_cast(1,Vector2.RIGHT*400);await frames(110)
	check(count_kind("fire_round")==10 and is_equal_approx(sum_damage(2),base_j_damage*1.35),"T23 Echo J replays once with its own activation hit cap")
	await prepare()
	check(not controller.augments.can_bind(split,controller.runtime_for(2)) and not controller.augments.can_bind(split,controller.runtime_for(4)),"T21 Split fails closed on grenade and rocket")
	var area:=load("res://content/augments/mechanics/area_expand.tres") as AugmentDefinition
	for slot in [2,3,4]:check(controller.augments.apply_bound(area,controller.runtime_for(slot)),"Area expand binds ordnance%d"%slot)
	var a:=echo.duplicate(true) as AugmentDefinition;var b:=echo.duplicate(true) as AugmentDefinition
	a.id=&"augment.fixture_a";b.id=&"augment.fixture_b";a.requirements.excluded_ids=[b.id];b.requirements.excluded_ids=[a.id]
	var first_manager:=AugmentManager.new();var second_manager:=AugmentManager.new()
	check(first_manager.apply_bound(a,controller.runtime_for(1)) and not first_manager.apply_bound(b,controller.runtime_for(1)) and second_manager.apply_bound(b,controller.runtime_for(1)) and not second_manager.apply_bound(a,controller.runtime_for(1)),"T22 shared bidirectional conflict lock on real J runtime")
	await prepare()
	check(controller.auto_step()==0,"T18 Manual never auto casts")
	controller.set_mode(&"AUTO");check(controller.auto_step()>0,"T18 Auto uses same data executors")
	combat.clear_transients();await frames(2)
	check(combat.get_child_count()==0,"reset cleans ordnance/mines/timers")
	for actor in actors:actor.queue_free()
	actors.clear();combat.queue_free();await process_frame
	await scene_checks()
	print("RESULT graveshade: checks=%d failures=%d"%[checks,failures]);quit(0 if failures==0 else 1)
func scene_checks() -> void:
	var settings:=root.get_node("AppSettings") as SettingsService
	var previous: StringName=settings.mode();settings.set_mode(&"MANUAL")
	var game: TrainingRun=(load("res://scenes/run/training_run.tscn") as PackedScene).instantiate()
	game.loadout_id=&"loadout.graveshade";game.basic_auto=false;root.add_child(game)
	check(game.player.sprite_visual!=null and game.player.get_node_or_null("TacticalEffects")!=null,"T29 actual training source actor and effects bind")
	var renderer:=game.player.get_node("TacticalEffects") as TacticalActorEffects
	renderer.clear();await frames(2)
	var visual_point: Vector2=game.player.global_position+Vector2(100,0)
	renderer._event({"kind":"burning_ground","skill":&"skill.graveshade.k","position":visual_point,"radius":105.0,"duration":3.0})
	var ground:=renderer.layer.get_child(0) as TacticalVisual
	check(ground.sequence.is_empty() and ground.ground_radius==105 and ground.lifetime==3,"burning ground keeps true area without looping explosion sprites")
	renderer._event({"kind":"explosion","skill":&"skill.graveshade.k","position":visual_point,"radius":105.0,"duration":.35})
	var blast:=renderer.layer.get_child(2) as TacticalVisual
	check(blast.size_px.is_equal_approx(Vector2(126,126)) and is_equal_approx(blast.lifetime,.24),"source explosion is60percent former diameter and shorter")
	var ring:=renderer.layer.get_child(1) as TacticalVisual
	check(ring.warning_radius==105,"subtle boundary retains actual105px damage radius")
	renderer._event({"kind":"burn_tick","skill":&"skill.graveshade.k","position":visual_point,"radius":105.0,"duration":.35})
	check((renderer.layer.get_child(3) as TacticalVisual).sequence.is_empty(),"burn damage tick adds no repeated source explosion")
	renderer.clear();await frames(2)
	game.request_basic_attack();await frames(20)
	check(renderer.shown.get("bullet",0)>0 and renderer.shown.get("muzzle",0)>0,"T05 source muzzle and tracer follow actual basic")
	check(game.player.cast_origin_offset==Vector2(32,-46),"source gun muzzle socket drives real projectile origin")
	check(game.player.action_audio.profile.basic[0].path.ends_with("0_16.wav"),"T04 source gun cue, no S1 voice bank on basic")
	for slot in range(1,5):game.skills.request_cast(slot,Vector2.RIGHT*100)
	await frames(110)
	check(renderer.shown.get("grenade",0)>0 and renderer.shown.get("mine",0)>0 and renderer.shown.get("rocket",0)>0,"T29 actual source grenade mine rocket play in Godot")
	check(game.player.action_audio.voices.size()==12 and game.player.action_audio.pending.size()<=64,"T28 bounded12voice64queue")
	if DisplayServer.get_name()!="headless":check(game.player.action_audio.voices_started>0,"T04 actual GUI AudioStreamPlayer2D playback")
	game.request_pause();await process_frame
	var snapshot: int=game.combat.event_count
	for i in range(5):await process_frame
	check(game.combat.event_count==snapshot,"T24 pause freezes gameplay events")
	game.request_pause()
	game.reset_training();await frames(3)
	check(not game.combat.get_children().any(func(node: Node) -> bool:return node is TacticalMine),"training reset removes mines")
	game.queue_free();await process_frame
	var menu: Node=(load("res://scenes/bootstrap/main.tscn") as PackedScene).instantiate();root.add_child(menu);await process_frame;await process_frame
	var slots:=menu.find_child("CharacterSlots",true,false) as GridContainer
	var locked: int=0
	for child in slots.get_children():
		if child is Button and (child as Button).disabled:locked+=1
	check(slots.get_child_count()==20 and locked==14,"20 character slots, six heroes and14unknown")
	menu._select_character(&"loadout.graveshade")
	check(menu._selected_loadout==&"loadout.graveshade","T18 sixthhero selectable")
	menu._start_run();await process_frame
	var normal:=current_scene as CombatRunRoot
	check(normal!=null and normal.loadout_id==&"loadout.graveshade","actual selected sixthhero starts PLAY")
	normal.set_physics_process(false);normal.player.set_physics_process(false);normal.skills.sync_level(11)
	var enemy: EnemyActor=normal.spawn_enemy()
	check(enemy!=null and enemy.global_position.distance_to(normal.player.global_position)>=550,"PLAY keeps safe550spawn")
	if enemy!=null:
		enemy.set_physics_process(false);enemy.position=normal.player.position+Vector2(75,0);enemy.health=TrainingHealth.new(100000);normal.skills.candidates=[enemy]
	var key:=InputEventKey.new();key.physical_keycode=settings.binding_for(&"active_1");key.pressed=true
	Input.parse_input_event(key);await frames(15)
	check(normal.skills.runtime_for(1).cooldown_remaining>0,"current remappable physical J key casts in PLAY")
	var sprite: ActorSprite=normal.player.sprite_visual
	sprite.play_action(&"cast_j");sprite.set_frame_and_progress(3,.4);sprite.play_action(&"cast_j")
	check(sprite.frame==3,"burst projectile events do not reset source body animation everyround")
	normal.skills.set_mode(&"AUTO");check(normal.skills.auto_step()>0,"actual PLAY Auto uses same accepted skills")
	normal.progression.add_xp(40);await process_frame
	check(paused and normal.state.run_phase==&"UPGRADE" and normal._offer.size()==3,"T24 actual level-up modal pauses with exactly3 valid offers")
	normal.request_upgrade(0);await process_frame
	check(not paused and normal.state.run_phase==&"RUNNING","T24 selected upgrade resumes sixthhero")
	normal.player.health.commit_resolved_hp(0);await process_frame;await process_frame
	check(normal.state.run_phase==&"DEAD" and String(normal.player.sprite_visual.animation).begins_with("death_"),"actual death plays decoded source knockdown pose")
	check(normal.combat.get_child_count()==0,"actual death clears all ordnance and proc timers")
	paused=false
	normal.queue_free();await process_frame
	settings.set_mode(previous)
