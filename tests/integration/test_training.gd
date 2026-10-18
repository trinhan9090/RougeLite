extends SceneTree
var checks: int=0
var failures: int=0
var kills: int=0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks+=1
	if value: print("PASS ",label)
	else: failures+=1;printerr("FAIL ",label)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run_tests() -> void:
	var original_settings := root.get_node("AppSettings") as SettingsService
	var saved_mode: StringName=original_settings.mode()
	root.remove_child(original_settings)
	var fixture := SettingsService.new("user://training_settings_fixture.cfg")
	fixture.name="AppSettings"
	root.add_child(fixture)
	fixture.set_mode(&"MANUAL")
	for hero: String in ["astra","vex","boros","atyu"]:
		var game := (load("res://scenes/run/training_run.tscn") as PackedScene).instantiate() as TrainingRun
		game.loadout_id=StringName("loadout."+hero)
		root.add_child(game)
		game.set_physics_process(false)
		game.player.set_physics_process(false)
		game.player.stats.crit_chance=0
		game.skills.set_mode(&"MANUAL")
		game.combat.resolver.events.actor_killed.connect(func(_c: CombatContext,_r: DamageResult) -> void: kills+=1)
		check(game.player.health is TrainingHealth and game.boss.health is TrainingHealth,hero+" training health isolated")
		check(game.skills.runtime_for(4).rank==1 and game.state.current_level==11,hero+" all skills unlocked without offers")
		check(game._enemies.size()==1 and game.spawn_enemy()==null,hero+" single boss no ordinary waves")
		var before: Vector2=game.boss.position
		var lethal := SkillRankDefinition.new()
		lethal.damage=1000000000
		lethal.damage_type="TRUE"
		var result: DamageResult=game.combat.hit(game.player,game.boss,lethal,game.combat.next_context(game.player,&"test.lethal"))
		check(result.accepted and result.mitigated_damage==lethal.damage,hero+" real giant hit accepted and measured")
		check(not result.killed and result.hp_damage==0 and game.boss.health.current==game.boss.health.maximum,hero+" boss cannot die even on lethal hit")
		check(game.total_damage==lethal.damage and game.hit_count==1,hero+" metrics use real mitigated damage")
		result=game.combat.hit(game.boss,game.player,lethal,game.combat.next_context(game.boss,&"test.player_lethal"))
		check(result.accepted and not result.killed and game.player.health.current==game.player.health.maximum,hero+" player remains full HP on lethal")
		check(kills==0 and game.kills==0 and game._loot.get_child_count()==0,hero+" no false kill or XP events")
		check(game._basic.step(1,[game.boss],game.combat),hero+" real auto basic reaches dummy")
		var slot: int=1
		check(game.skills.request_cast(slot,Vector2.RIGHT*400),hero+" first active accepted")
		check(game.skills.runtime_for(slot).cooldown_remaining==0,hero+" cooldown clears immediately after accepted cast")
		check(game.skills.request_cast(slot,Vector2.RIGHT*400),hero+" same active repeats without waiting")
		await frames(24)
		check(game.boss.position==before and game.boss.attacks_started==0 and game._enemy_attacks.is_empty(),hero+" boss stays stationary and never attacks")
		check(game.boss.health.is_alive() and game.state.run_phase==&"RUNNING",hero+" test damage does not transition or end run")
		game.skills.request_cast(3,Vector2.RIGHT*400)
		(game.panel.find_child("TrainingReset",true,false) as Button).pressed.emit()
		for i in range(5): await process_frame
		game.set_physics_process(false)
		game.player.set_physics_process(false)
		check(game.player.position==Vector2.ZERO and game.boss.position==TrainingRun.DUMMY_POSITION and game.hit_count==0 and not game.player.motion_active,hero+" reset clears position motion and metrics")
		game.request_pause()
		check(paused and game.state.run_phase==&"PAUSED",hero+" pause works")
		game.request_pause()
		check(not paused and game.state.run_phase==&"RUNNING",hero+" resume works")
		(game.panel.find_child("TrainingRank",true,false) as OptionButton).item_selected.emit(3)
		for i in range(5): await process_frame
		game.set_physics_process(false)
		check(game.skills.runtime_for(1).rank==4 and game.skills.runtime_for(4).rank==3,hero+" rank selector rebuild respects ultimate cap")
		check(game._enemies.size()==1 and game._actors.get_children().filter(func(node: Node) -> bool: return node is TrainingBoss).size()==1,hero+" retry has one dummy")
		game.player.set_physics_process(false)
		fixture.set_mode(&"AUTO")
		game._auto_left=0
		var sequence: int=game.skills.runtime_for(1).cast_sequence_number
		for i in range(10): game._physics_process(.1)
		check(game.skills.runtime_for(1).cast_sequence_number-sequence==4 and game.skills.runtime_for(1).cooldown_remaining==0,hero+" Auto cadence bounded while cooldown stays zero")
		fixture.set_mode(&"MANUAL")
		game.queue_free()
		await process_frame
	var menu := (load("res://scenes/bootstrap/main.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	check(menu.find_child("TrainingButton",true,false)!=null,"home exposes TRAINING")
	menu._select_character(&"loadout.atyu")
	(menu.find_child("TrainingButton",true,false) as Button).pressed.emit()
	await process_frame
	var training := current_scene as TrainingRun
	check(training!=null and training.loadout_id==&"loadout.atyu","menu training uses selected character")
	if training!=null:
		(training.panel.find_child("TrainingHero",true,false) as OptionButton).item_selected.emit(1)
		for i in range(5): await process_frame
		check(training.loadout_id==&"loadout.vex" and training._profile.display_name=="Vex" and training._enemies.size()==1,"training hero selector switches actual loadout")
		training.queue_free()
	await process_frame
	var normal := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(normal)
	normal.set_physics_process(false)
	check(not normal is TrainingRun and not normal.player.health is TrainingHealth and normal.skills.runtime_for(4).rank==0 and normal.state.current_level==1,"ordinary PLAY remains normal HP level1 and locked skills")
	normal.queue_free()
	await process_frame
	fixture.queue_free()
	await process_frame
	root.add_child(original_settings)
	check(original_settings.mode()==saved_mode,"training tests preserve user's settings")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://training_settings_fixture.cfg"))
	print("RESULT training: checks=%d failures=%d"%[checks,failures])
	quit(0 if failures==0 else 1)
