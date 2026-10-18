class_name TrainingRun
extends CombatRunRoot
var training_rank: int = 1
var basic_auto: bool=true
var hit_count: int = 0
var total_damage: float = 0
var last_damage: float = 0
var _first_hit: float = -1
var _auto_left: float = 0
var _training_layer: CanvasLayer
var panel: TrainingPanel
const DUMMY_POSITION: Vector2 = Vector2(75,0)

func _start_run() -> void:
	if is_instance_valid(_training_layer): _training_layer.queue_free()
	super._start_run()
	player.health=TrainingHealth.new(player.health.maximum)
	player.health.changed.connect(func(_hp: float,_max: float) -> void: player.queue_redraw())
	state.current_level=11
	skills.sync_level(11)
	for slot in range(1,5):
		for i in range(mini(training_rank,skills.runtime_for(slot).definition.max_rank)-1): skills.upgrade_rank(slot)
	skills.skill_cast.connect(func(_slot: int,_context: CombatContext) -> void: skills.advance_cooldowns(1000000))
	boss=TrainingBoss.new()
	boss.name="TrainingBoss"
	boss.actor_id=2
	boss.boss_definition=(get_node("/root/ContentRegistry") as ContentRegistryService).definition_copy(&"boss.stone_warden") as BossDefinition
	boss.combat=combat
	boss.position=DUMMY_POSITION
	boss.collision_layer=2
	boss.collision_mask=4
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius=30
	collider.shape=shape
	boss.add_child(collider)
	_actors.add_child(boss)
	_enemies.append(boss)
	skills.candidates=[boss]
	combat.resolver.events.damage_applied.connect(_on_training_damage)
	_training_layer=CanvasLayer.new()
	_training_layer.layer=0 # normal pause/modal layer must remain above training controls
	add_child(_training_layer)
	panel=TrainingPanel.new()
	panel.hero_id=loadout_id
	panel.skill_rank=training_rank
	panel.basic_auto=basic_auto
	panel.basic_auto_changed.connect(func(value: bool) -> void: basic_auto=value)
	panel.hero_selected.connect(func(id: StringName) -> void: loadout_id=id;request_retry())
	panel.rank_selected.connect(func(value: int) -> void: training_rank=value;request_retry())
	panel.reset_requested.connect(reset_training)
	_training_layer.add_child(panel)
	hit_count=0;total_damage=0;last_damage=0;_first_hit=-1;_auto_left=0
	presentation.announce("TRAINING — đầy máu, chiêu hồi 0s, boss bất tử")
	_present_hud()
	print("TRAINING_READY hero=%s rank=%d"%[loadout_id,training_rank])

func _change_map() -> void:
	state.map_id=&"map.ruined_temple"
	var map := (get_node("/root/ContentRegistry") as ContentRegistryService).definition_copy(state.map_id) as MapDefinition
	_arena.apply_layout(map,[])
	maps_visited+=1

func _physics_process(delta: float) -> void:
	if state==null or state.run_phase!=&"RUNNING" or not state.alive: return
	var settings := get_node("/root/AppSettings") as SettingsService
	player.manual_aim=settings.mode()==&"MANUAL"
	state.elapsed_simulation_seconds+=delta
	player.health.commit_resolved_hp(player.health.maximum)
	if basic_auto: _basic.step(delta,_enemies,combat)
	else: _basic.cooldown_left=maxf(0,_basic.cooldown_left-delta)
	skills.candidates=_enemies
	skills.set_mode(settings.mode())
	skills.advance_cooldowns(1000000)
	_auto_left-=delta
	if _auto_left<=0:
		_auto_left=.25
		skills.auto_step()
	_hud_clock-=delta
	if _hud_clock<=0:
		_hud_clock=.1
		_present_hud()
		panel.present(hit_count,total_damage,last_damage,total_damage/maxf(1,state.elapsed_simulation_seconds-_first_hit) if _first_hit>=0 else 0)

func _on_training_damage(_context: CombatContext,result: DamageResult) -> void:
	if result.target_id!=boss.actor_id or not result.accepted: return
	hit_count+=1
	last_damage=result.mitigated_damage
	total_damage+=last_damage
	if _first_hit<0: _first_hit=state.elapsed_simulation_seconds

func reset_training() -> void:
	if state.run_phase!=&"RUNNING": return
	# Rebuild after queued nodes have left the tree, including delayed procs,
	# rank effects and active movement. No old effect can hit the new dummy.
	request_retry()

func spawn_enemy() -> EnemyActor:
	return null # Training has one authored dummy, never production waves.
