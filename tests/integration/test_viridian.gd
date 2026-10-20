extends SceneTree
var checks: int=0
var failures: int=0
var owner: PlayerActor
var targets: Array[Actor]=[]
var combat: CombatService
var controller: SkillController
var profile: CombatLoadoutDefinition
var manager: AugmentManager
var events: Array[Dictionary]=[]
var beam_events: int=0
func _initialize() -> void:call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks+=1
	if value: print("PASS ",label)
	else:failures+=1;printerr("FAIL ",label)
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		for target in targets:
			if is_instance_valid(target):target.advance_effects(1.0/60)
	await process_frame
func prepare(rank: int=1) -> void:
	combat.clear_transients()
	await process_frame
	owner.clear_temporary()
	owner.position=Vector2.ZERO;owner.record_attack_direction(Vector2.RIGHT)
	manager=AugmentManager.new()
	controller=SkillController.new(1,profile.active_skills,profile.basic_attack)
	controller.bind(owner,combat);controller.augments=manager;controller.candidates=targets;controller.set_mode(&"MANUAL");controller.sync_level(11)
	for slot in range(1,5):
		for i in range(mini(rank,controller.runtime_for(slot).definition.max_rank)-1):controller.upgrade_rank(slot)
	for target in targets:
		target.position=Vector2(90,-24);target.health=Health.new(50000);target.statuses=StatusController.new();target.is_boss=false
	events.clear();beam_events=0
func damage_to(id: int) -> float:
	var result: float=0
	for event in events:
		if event.target==id:result+=event.damage
	return result
func run_tests() -> void:
	var registry:=root.get_node("ContentRegistry") as ContentRegistryService
	check(registry.validate_all().is_empty(),"all content validates with fifth hero")
	profile=registry.definition_copy(&"loadout.viridian") as CombatLoadoutDefinition
	check(profile!=null and profile.stats.max_hp==95 and profile.stats.move_speed==215,"Viridian Mage stats data")
	check(profile.art_frames.get_animation_names().size()==36 and profile.art_frames.get_meta("side_view",false) and profile.art_frames.get_frame_count(&"idle_east")==14,"source nine-state side-view animation aliases")
	owner=PlayerActor.new();owner.actor_id=1;owner.stats_definition=profile.stats;owner.cast_origin_offset=profile.cast_origin_offset
	root.add_child(owner);owner.set_physics_process(false);owner.stats.crit_chance=0
	for i in range(3):
		var target:=Actor.new();target.actor_id=i+2;target.team=2;target.stats_definition=ActorStatDefinition.new();root.add_child(target);target.stats.armor=0;targets.append(target)
	combat=CombatService.new();combat.rng=RunRng.new(87).stream(&"combat");root.add_child(combat)
	combat.actor_provider=func() -> Array[Actor]:
		var all: Array[Actor]=[owner];all.append_array(targets);return all
	combat.resolver.events.damage_applied.connect(func(context: CombatContext,result: DamageResult) -> void:events.append({"target":result.target_id,"damage":result.mitigated_damage,"root":context.root_cast_id,"secondary":context.is_secondary}))
	combat.visual_event.connect(func(event: Dictionary) -> void:
		if event.kind=="beam" and event.get("skill")==&"skill.viridian.i":beam_events+=1)
	await prepare()
	var locked:=SkillController.new(1,profile.active_skills)
	check(locked.sync_level(2).is_empty() and locked.sync_level(3)==[1] and locked.sync_level(6)==[2] and locked.sync_level(9)==[3] and locked.sync_level(11)==[4],"unlock thresholds3/6/9/11")
	check(controller.auto_step()==0,"Manual never auto-casts")
	check(controller.request_cast(1,Vector2.LEFT*500),"J accepts current last-attack direction ignoring cursor")
	check(damage_to(2)==0,"J telegraph before hit")
	await frames(15)
	check(damage_to(2)==48 and damage_to(3)==48,"J multi-target48 damage once each")
	check(not controller.request_cast(1,Vector2.RIGHT*500),"J normal cooldown enforced")
	await prepare(4)
	targets[0].is_boss=true
	controller.request_cast(1,Vector2.RIGHT)
	await frames(100)
	check(is_equal_approx(damage_to(2),48*1.3+14),"J rank3 boss bonus and rank4 two plasma ticks")
	check(profile.active_skills[0].rank_scaling[0].radius_px==12,"rank definition unchanged")
	await prepare()
	for target in targets:target.position=Vector2(330,0)
	controller.request_cast(2,Vector2.LEFT*500)
	await frames(20)
	check(damage_to(2)==15 and targets[0].statuses.movement_factor()==0,"K .24s pulse15 and real normal root")
	await frames(100)
	check(damage_to(2)==15 and targets[0].statuses.movement_factor()==1,"K one initial hit and finite root")
	await prepare(4)
	for target in targets:target.position=Vector2(330,0)
	targets[0].is_boss=true
	controller.request_cast(2,Vector2.RIGHT)
	await frames(17)
	check(targets[0].statuses.stunned(),"K boss uses authoritative .15s stagger")
	await frames(15)
	check(not targets[0].statuses.stunned(),"boss CC cap preserved")
	await frames(120)
	check(damage_to(2)==60,"K rank4 initial15 plus exit45 exactly once")
	await prepare()
	targets[0].position=Vector2(52,0)
	controller.request_cast(3,Vector2.RIGHT)
	check(owner.health.shield_total()==55,"L grants55 shield instantly")
	await frames(25)
	check(damage_to(2)==12,"orb contact hit once within .7 ICD")
	controller.advance_cooldowns(100)
	check(controller.request_cast(3,Vector2.RIGHT) and owner.health.shield_total()==55,"L refresh replaces shield/orbits without stacking")
	var orbit:=owner.get_meta("orbit_runtime") as WeakRef
	check((orbit.get_ref() as ControlMageRuntime).intent.rank.projectile_count==2,"rank1 two actual orbitals")
	await frames(430)
	check(owner.health.shield_total()==0 and not owner.has_meta("orbit_runtime"),"shield and orbs expire7s")
	await prepare(4)
	controller.request_cast(3,Vector2.RIGHT)
	orbit=owner.get_meta("orbit_runtime") as WeakRef
	check(owner.health.shield_total()==80 and (orbit.get_ref() as ControlMageRuntime).intent.rank.projectile_count==4,"L rank4 four orbs shield80")
	await prepare()
	targets[0].position=Vector2(5,-24) # Every ray overlaps this point; global cap still two.
	controller.request_cast(4,Vector2.RIGHT)
	check(owner.has_meta("movement_lock_runtime"),"ultimate locks movement for intro and ray release")
	check(not controller.request_cast(4,Vector2.RIGHT),"cannot overlap active channels")
	await frames(36)
	check(damage_to(2)==0,"I .65s windup")
	await frames(60)
	check(damage_to(2)==136,"five rays respect two hits per target")
	check(owner.factor(&"move_speed")==1 and not owner.has_meta("channel_runtime"),"channel cleanup restores movement")
	await prepare()
	for target in targets:target.position=Vector2(900,900)
	controller.request_cast(4,Vector2.RIGHT)
	var ray_runtime:=owner.get_meta("channel_runtime").get_ref() as ControlMageRuntime
	ray_runtime.set_physics_process(false)
	ray_runtime._fire_ray(owner,0)
	var lane: Dictionary=ray_runtime.active_rays[0]
	var lane_origin: Vector2=lane.origin
	var lane_direction: Vector2=lane.direction
	var hurtbox:=ActorHurtbox.new();targets[0].add_child(hurtbox)
	hurtbox.configure(targets[0],Vector2(0,-18),Vector2(24,32));targets[0].hurtbox=hurtbox
	await frames(2)
	ray_runtime._advance_rays(owner)
	check(damage_to(2)==0,"I empty lane does not damage distant target")
	targets[0].position=lane_origin+lane_direction*250+Vector2(0,18)
	await frames(2)
	ray_runtime.elapsed=.08;ray_runtime._advance_rays(owner)
	check(damage_to(2)==68,"I torso entering an already visible ray is hit")
	ray_runtime.elapsed=.12;ray_runtime._advance_rays(owner)
	check(damage_to(2)==68,"I same ray cannot rehit each physics frame")
	owner.position=Vector2(100,100)
	check(lane.origin==lane_origin,"I emitted hitbox origin stays fixed when caster moves")
	targets[1].position=lane_origin+lane_direction*300+lane_direction.orthogonal()*60
	ray_runtime._advance_rays(owner)
	check(damage_to(3)==0,"I gap beside individual ray is not whole-fan damage")
	targets[1].position=lane_origin+lane_direction*300
	ray_runtime.elapsed=.19;ray_runtime._advance_rays(owner)
	check(damage_to(3)==0 and ray_runtime.active_rays.is_empty(),"I expired ray cannot hit a late entrant")
	hurtbox.queue_free();targets[0].hurtbox=null
	await prepare(3)
	targets[0].position=Vector2(5,-24);targets[1].position=Vector2(460,-24);targets[2].position=Vector2(900,0)
	controller.request_cast(4,Vector2.RIGHT);await frames(105)
	check(beam_events==9 and damage_to(2)==136,"rank3 nine rays keep global two-hit cap")
	check(damage_to(3)==123,"rank3 endpoint ray68 plus final55 burst once")
	await prepare()
	var reflect:=load("res://content/augments/mechanics/shield_reflect.tres") as AugmentDefinition
	check(manager.apply_bound(reflect,controller.runtime_for(3)) and not manager.can_bind(reflect,controller.runtime_for(1)),"shield reflection compatible L and rejected J")
	controller.request_cast(3,Vector2.RIGHT)
	var incoming:=SkillRankDefinition.new();incoming.damage=25;incoming.damage_type="MAGIC"
	combat.hit(targets[0],owner,incoming,combat.next_context(targets[0],&"test.incoming"));await frames(3)
	check(is_equal_approx(damage_to(2),2) and owner.health.shield_total()==30,"L reuses shared8percent shield reflect without recursion")
	await prepare()
	var split:=load("res://content/augments/mechanics/projectile_split.tres") as AugmentDefinition
	check(manager.apply_bound(split,controller.runtime_for(0)),"Split binds real basic projectile")
	var basic:=AttackController.new(owner,profile.basic_attack)
	basic.runtime=controller.runtime_for(0);basic.augments=manager
	check(basic.step(0,targets,combat),"Split basic accepts actual projectile attack")
	var bolts: int=0
	for child in combat.get_children():
		if child is CombatProjectile:bolts+=1
	check(bolts==3,"Split basic spawns three real shared projectiles")
	combat.clear_transients();await process_frame
	for slot in range(1,5):check(not manager.can_bind(split,controller.runtime_for(slot)),"Split rejected for active%d"%slot)
	var echo:=load("res://content/augments/mechanics/echo_cast.tres") as AugmentDefinition
	check(manager.apply_bound(echo,controller.runtime_for(1)),"Echo compatible J")
	controller.request_cast(1,Vector2.RIGHT)
	await frames(70)
	check(is_equal_approx(damage_to(2),48*1.35),"J shared Echo once without echo-of-echo")
	await prepare()
	check(manager.apply_bound(echo,controller.runtime_for(2)),"Echo compatible K")
	for target in targets:target.position=Vector2(330,0)
	controller.request_cast(2,Vector2.RIGHT)
	await frames(70)
	check(is_equal_approx(damage_to(2),15*1.35),"K shared Echo pulse bounded")
	check(not manager.can_bind(echo,controller.runtime_for(3)) and not manager.can_bind(echo,controller.runtime_for(4)),"guarded orbit/channel Echo fails closed")
	await prepare()
	var elite:=EnemyActor.new();elite.actor_id=5;elite.definition=EnemyDefinition.new();elite.definition.id=&"enemy.elite_brute";elite.definition.stats=ActorStatDefinition.new();elite.definition.stats.max_hp=50000
	elite.position=Vector2(330,0);root.add_child(elite);elite.set_physics_process(false);targets.append(elite)
	for target in targets:target.position=Vector2(330,0)
	controller.candidates=targets
	controller.request_cast(2,Vector2.RIGHT)
	await frames(60)
	check(elite.statuses.movement_factor()==1 and targets[0].statuses.movement_factor()==0,"K elite .7s root vs normal1.6s")
	targets.erase(elite);elite.queue_free();await process_frame
	await prepare()
	var expand:=load("res://content/augments/mechanics/area_expand.tres") as AugmentDefinition
	check(manager.apply_bound(expand,controller.runtime_for(1)),"J width expand compatible")
	targets[0].position=Vector2(90,-11) # offset13 exceeds base12 but within expanded13.44
	controller.request_cast(1,Vector2.RIGHT)
	await frames(15)
	check(damage_to(2)==48,"expanded beam query agrees with width")
	await prepare()
	check(manager.apply_bound(expand,controller.runtime_for(2)),"K area expansion compatible")
	targets[0].position=Vector2(423,0)
	var isolated_candidates: Array[Actor]=[targets[0]]
	controller.candidates=isolated_candidates # do not mutate shared target fixture array
	controller.request_cast(2,Vector2.RIGHT);await frames(20)
	check(damage_to(2)==15,"expanded prison hits beyond base86 radius")
	await prepare()
	controller.set_mode(&"AUTO")
	targets[0].position=Vector2(90,0);targets[1].position=Vector2(280,0);targets[2].position=Vector2(285,0)
	check(controller.request_cast(2),"Auto K accepts nearest placement")
	var prison: ControlMageRuntime
	for child in combat.get_children():if child is ControlMageRuntime:prison=child
	check(prison!=null and prison.center.is_equal_approx(Vector2(90,0)),"Auto chooses nearest isolated target over denser distant cluster")
	await prepare()
	controller.request_cast(4,Vector2.RIGHT)
	owner.statuses.apply(_stun())
	await frames(2)
	check(owner.factor(&"move_speed")==1 and not owner.has_meta("channel_runtime"),"stun interrupts channel and cleans movement state")
	owner.queue_free()
	for target in targets:target.queue_free()
	combat.queue_free();await process_frame
	targets.clear()
	await run_scene_checks()
	print("RESULT viridian: checks=%d failures=%d"%[checks,failures])
	quit(0 if failures==0 else 1)
func _stun() -> StatusEffectDefinition:
	var effect:=StatusEffectDefinition.new();effect.kind="stun";effect.duration=1;return effect
func run_scene_checks() -> void:
	var settings:=root.get_node("AppSettings") as SettingsService
	var old_mode: StringName=settings.mode();settings.set_mode(&"MANUAL")
	var game: TrainingRun=(load("res://scenes/run/training_run.tscn") as PackedScene).instantiate()
	game.loadout_id=&"loadout.viridian";root.add_child(game);game.basic_auto=false;game.set_physics_process(false);game.player.set_physics_process(false)
	var renderer:=game.player.get_node("MappedEffects") as MappedActorEffects
	game.player.facing=Vector2.UP;game.player.record_attack_direction(Vector2.RIGHT)
	check(game.player.sprite_visual._resolve(&"cast_j")==&"cast_j_east" and game.player.sprite_visual._resolve(&"run")==&"run_north","directional cast pose follows attack while run follows movement")
	var bolt_config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/private_viridian/profile.json"))
	check(not bool(bolt_config.get("bolt_layers",false)) and renderer.basic_impact_size==16,"Doom uses source orb without supplemental bolt layers")
	check(renderer!=null and game.player.action_audio!=null,"actual run binds mapped VFX and positional audio")
	check(game.player.action_audio.profile.basic[0].path=="res://assets/viridian/audio/emerald_shot.wav","basic guaranteed original non-voice shot")
	check(game.player.action_audio.profile["impact:skill.viridian.basic"][0].path.ends_with("emerald_hit.wav"),"basic impact guaranteed non-voice")
	game.request_basic_attack()
	if DisplayServer.get_name()!="headless":check(game.player.action_audio.voices.any(func(voice: AudioStreamPlayer2D) -> bool:return voice.playing),"real basic command starts a playing2D stream")
	await frames(15)
	check(renderer.shown.get("bolt",0)>0,"shared projectile displays actual source sprite")
	game.skills.request_cast(1,Vector2.RIGHT*500);await frames(20)
	check(renderer.shown.get("beam",0)>0,"actual J mapped source beam")
	game.boss.position=Vector2(330,0);game.skills.request_cast(2,Vector2.RIGHT*500);await frames(20)
	check(renderer.shown.get("prison",0)>0,"actual K mapped source cage")
	game.skills.request_cast(3,Vector2.RIGHT);await frames(2)
	check(renderer.shown.get("orb",0)==2,"two real moving source orbital sprites")
	game.skills.request_cast(4,Vector2.RIGHT);await frames(100)
	check(renderer.shown.get("ultimate",0)==5,"five mapped ultimate rays")
	if DisplayServer.get_name()!="headless":check(game.player.action_audio.voices_started>0,"GUI actual 2D audio playback")
	game.reset_training();await process_frame;await process_frame
	check(not game.player.has_meta("orbit_runtime") and not game.player.has_meta("channel_runtime"),"reset clears new temporary effects")
	game.queue_free();await process_frame
	var menu: Node=(load("res://scenes/bootstrap/main.tscn") as PackedScene).instantiate()
	root.add_child(menu);await process_frame;await process_frame
	menu._show_page(&"CHARACTER")
	var slots:=menu.find_child("CharacterSlots",true,false) as GridContainer
	check(slots.get_child_count()==20 and not (slots.get_child(4) as Button).disabled,"fifth avatar available in twenty-slot selection")
	(slots.get_child(4) as Button).pressed.emit()
	(menu.find_child("SelectViridian",true,false) as Button).pressed.emit()
	menu._start_run();await process_frame
	var normal:=current_scene as CombatRunRoot
	check(normal!=null and normal.loadout_id==&"loadout.viridian","selected Viridian starts actual PLAY")
	normal.set_physics_process(false);normal.player.set_physics_process(false)
	normal.skills.sync_level(11)
	var enemy: EnemyActor=normal.spawn_enemy()
	check(enemy!=null and enemy.global_position.distance_to(normal.player.global_position)>=550,"PLAY enemy respects spawn safety")
	if enemy!=null:
		enemy.set_physics_process(false);enemy.health=TrainingHealth.new(50000);enemy.position=normal.player.position+Vector2(75,0)
		normal.skills.candidates=[enemy]
	var input:=InputEventKey.new();input.pressed=true;input.physical_keycode=settings.binding_for(&"active_1")
	Input.parse_input_event(input);await frames(20)
	check(normal.skills.runtime_for(1).cooldown_remaining>0,"current physical J binding casts in PLAY")
	normal.skills.set_mode(&"AUTO")
	check(normal.skills.auto_step()>0,"Auto casts through same PLAY controller")
	normal.combat.clear_transients();await frames(2)
	check(not normal.player.has_meta("orbit_runtime") and not normal.player.has_meta("channel_runtime"),"map-style clear removes orbital/channel runtimes")
	normal.state.current_level=10;normal.state.current_xp=0
	normal.gate.request(10)
	for attempt in range(20):
		normal._spawn_boss()
		if normal.boss!=null:break
	check(normal.boss!=null,"real level-gated boss spawns for Viridian PLAY")
	var visited: int=normal.maps_visited
	if normal.boss!=null:
		var finishing:=SkillRankDefinition.new();finishing.damage=1000000;finishing.damage_type="MAGIC"
		normal.combat.hit(normal.player,normal.boss,finishing,normal.combat.next_context(normal.player,&"skill.viridian.basic"))
		for i in range(5):await process_frame
		check(normal.bosses_defeated==1 and normal.maps_visited==visited+1,"real boss death transitions map with new hero")
		check(not normal.player.has_meta("orbit_runtime") and not normal.player.has_meta("channel_runtime") and (normal.player.get_node("MappedEffects") as MappedActorEffects)._layer.get_child_count()==0,"actual map transition clears mapped effects and custom hit runtimes")
	paused=false
	normal.queue_free();await process_frame
	settings.set_mode(old_mode)
