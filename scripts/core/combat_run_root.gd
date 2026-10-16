class_name CombatRunRoot
extends RunRoot
## M1 composition root. Combat, targeting, XP and modifier rules live in services.

@export var loadout_id: StringName = &"loadout.astra"
@export var run_seed: int = 20261015
var player: PlayerActor
var progression: LevelManager
var augments: AugmentManager
var combat: CombatService
var presentation: RunPresentation
var kills: int = 0
var _profile: CombatLoadoutDefinition
var _arena: ArenaGeometry
var _actors: Node2D
var _loot: Node2D
var _camera: Camera2D
var _enemies: Array[Actor] = []
var _enemy_attacks: Dictionary[int, AttackController] = {}
var _basic: AttackController
var _next_actor_id: int = 2
var _spawn_clock: float = 0.0
var _spawn_config: SpawnDefinition
var _curve: ProgressionDefinition
var _stat_cores: Array[AugmentDefinition] = []
var _offer: Array[UpgradeOption] = []
var skills: SkillController
var _hud_clock: float = 0.0
var gate: BossGate
var boss: BossActor
var bosses_defeated: int = 0
var maps_visited: int = 0
var _map_bag: Array[StringName] = []
var _warning_left: float = 0
var audio: AudioFeedback
var _environment: Actor
var visual_factory: CombatVisualFactory

func _ready() -> void:
	var registry := get_node("/root/ContentRegistry") as ContentRegistryService
	if not registry.validate_all().is_empty():
		push_error("Combat content validation failed: %s" % registry.validate_all())
		get_tree().quit(1)
		return
	_arena = ArenaGeometry.new()
	add_child(_arena)
	_actors = Node2D.new()
	add_child(_actors)
	_loot = Node2D.new()
	add_child(_loot)
	var layer := CanvasLayer.new()
	add_child(layer)
	presentation = RunPresentation.new()
	layer.add_child(presentation)
	presentation.upgrade_selected.connect(request_upgrade)
	presentation.reroll_requested.connect(request_reroll)
	presentation.pause_requested.connect(request_pause)
	presentation.resume_requested.connect(request_pause)
	presentation.retry_requested.connect(request_retry)
	presentation.menu_requested.connect(request_menu)
	presentation.hud.skill_requested.connect(func(slot: int) -> void:
		if state != null and state.run_phase == &"RUNNING": skills.request_cast(slot,player.global_position + player.facing * 1000))
	_spawn_config = registry.definition_copy(&"config.spawn") as SpawnDefinition
	_curve = registry.definition_copy(&"progression.default") as ProgressionDefinition
	for content_id in registry.content_ids():
		if String(content_id).begins_with("stat.") or String(content_id).begins_with("augment."):
			_stat_cores.append(registry.definition_copy(content_id) as AugmentDefinition)
	_start_run()

func _start_run() -> void:
	var registry := get_node("/root/ContentRegistry") as ContentRegistryService
	_profile = registry.definition_copy(loadout_id) as CombatLoadoutDefinition
	state = RunState.new(run_seed, registry.content_version())
	state.run_phase = &"RUNNING"
	gate = BossGate.new(state)
	boss = null
	bosses_defeated = 0
	maps_visited = 0
	_map_bag.clear()
	_change_map()
	kills = 0
	_next_actor_id = 2
	_spawn_clock = 0.0
	_enemies.clear()
	_enemy_attacks.clear()
	_offer.clear()
	augments = AugmentManager.new()
	progression = LevelManager.new(state, _curve)
	progression.level_applied.connect(_on_level_applied)
	combat = CombatService.new()
	combat.max_projectiles = _spawn_config.max_projectiles
	combat.rng = state.rng.stream(&"combat")
	add_child(combat)
	if is_instance_valid(visual_factory): visual_factory.free()
	visual_factory = CombatVisualFactory.new()
	visual_factory.combat = combat
	var visual_color: Color = _profile.art_frames.get_meta("vfx_color",_profile.tint) if _profile.art_frames != null else _profile.tint
	visual_factory.colors[String(_profile.basic_attack.id)] = visual_color
	for skill in _profile.active_skills:
		visual_factory.colors[String(skill.id)] = visual_color
	add_child(visual_factory)
	player = (load("res://scenes/characters/player.tscn") as PackedScene).instantiate() as PlayerActor
	player.stats_definition = _profile.stats
	player.tint = _profile.tint
	player.weapon = _profile.weapon
	player.visual_frames = _profile.art_frames if _profile.art_frames != null else _profile.visual_frames
	player.actor_id = 1
	player.position = _arena.definition.safe_spawn_anchor
	_actors.add_child(player)
	player.died.connect(_on_player_died)
	_environment = Actor.new()
	_environment.actor_id = -1
	_environment.team = 3
	_environment.stats_definition = ActorStatDefinition.new()
	_environment.collision_layer = 0
	_actors.add_child(_environment)
	if audio == null:
		audio = AudioFeedback.new()
		add_child(audio)
	combat.resolver.events.damage_applied.connect(audio.on_damage)
	combat.resolver.events.damage_applied.connect(func(_context: CombatContext,result: DamageResult) -> void:
		if result.target_id == player.actor_id:
			if player.sprite_visual != null and player.health.is_alive() and player.visual_frames.get_meta("cardinal",false):
				player.sprite_visual.play_action(&"hit")
			player.modulate = Color("ffb0b0")
			get_tree().create_tween().tween_property(player,"modulate",Color.WHITE,.15))
	skills = SkillController.new(player.actor_id, _profile.active_skills, _profile.basic_attack)
	skills.bind(player, combat)
	skills.augments = augments
	skills.skill_cast.connect(func(slot: int,_context: CombatContext) -> void:
		player.attack_flash = .12
		if player.sprite_visual != null:
			if player.visual_frames.get_meta("cardinal",false):
				player.sprite_visual.play_action(StringName("cast_"+["j","k","l","i"][slot-1]))
				return
			var executor := skills.runtime_for(slot).definition.executor as EffectExecutorDefinition
			if executor != null and executor.kind != "dash":
				var actions: Dictionary = player.visual_frames.get_meta("skill_actions",{})
				player.sprite_visual.play_action(StringName(actions.get(executor.kind,"cast"))))
	progression.level_entered.connect(skills.sync_level)
	combat.actor_provider = func() -> Array[Actor]:
		var result: Array[Actor] = [player]
		for actor in _enemies:
			if is_instance_valid(actor): result.append(actor)
		return result
	_camera = Camera2D.new()
	_camera.limit_left = roundi(_arena.definition.bounds.position.x)
	_camera.limit_right = roundi(_arena.definition.bounds.end.x)
	_camera.limit_top = roundi(_arena.definition.bounds.position.y)
	_camera.limit_bottom = roundi(_arena.definition.bounds.end.y)
	player.add_child(_camera)
	_camera.make_current()
	_basic = AttackController.new(player, _profile.basic_attack)
	_basic.augments = augments
	_basic.runtime = skills.runtime_for(0)
	_basic.attack_fired.connect(func(target: Actor) -> void:
		if not player.manual_aim: player.facing = player.global_position.direction_to(target.global_position)
		player.attack_flash = 0.12
	)
	presentation.hide_modal()
	_present_hud()
	print("COMBAT_RUN_STARTED loadout=%s seed=%d" % [loadout_id, run_seed])

func _physics_process(delta: float) -> void:
	if is_instance_valid(player):
		player.manual_aim = (get_node("/root/AppSettings") as SettingsService).mode() == &"MANUAL"
	if state == null or state.run_phase != &"RUNNING" or not state.alive:
		return
	state.elapsed_simulation_seconds += delta
	if _arena.hazard_step(delta,player.global_position):
		var hazard := SkillRankDefinition.new()
		hazard.damage = _arena.definition.hazard_damage
		hazard.damage_type = "TRUE"
		hazard.behavior = SkillBehaviorDefinition.new()
		combat.hit(_environment,player,hazard,combat.next_context(_environment,&"environment.lava"))
		if not state.alive: return
	if state.boss_gate_state == &"PENDING":
		_warning_left -= delta
		if _warning_left <= 0: _spawn_boss()
	_enemies = _enemies.filter(func(actor) -> bool: return is_instance_valid(actor) and not actor.is_queued_for_deletion() and actor.health.is_alive())
	_basic.step(delta, _enemies, combat)
	skills.candidates = _enemies
	skills.set_mode((get_node("/root/AppSettings") as SettingsService).mode())
	skills.advance_cooldowns(delta)
	skills.auto_step()
	for controller: AttackController in _enemy_attacks.values():
		controller.step(delta, [player], combat)
		if not state.alive:
			return
	_spawn_clock -= delta
	if _spawn_clock <= 0.0:
		_spawn_clock += _spawn_config.period
		var pressure: float = 1.0 + 0.06 * (state.current_level - 1) + 0.01 * state.elapsed_simulation_seconds / 60.0
		for index in range(maxi(1, floori(pressure))):
			spawn_enemy()
	_hud_clock -= delta
	if _hud_clock <= 0.0:
		_hud_clock = 0.1
		_present_hud()

func spawn_enemy() -> EnemyActor:
	if _enemies.size() >= EnemySpawnDirector.population_cap(_spawn_config,state.current_level) or not state.alive:
		return null
	var visible := Rect2(_camera.get_screen_center_position() - get_viewport().get_visible_rect().size / 2.0, get_viewport().get_visible_rect().size)
	var point: Variant = EnemySpawnDirector.sample(player.global_position, visible, _arena, _spawn_config, state.rng.stream(&"spawns"), _enemies)
	if point == null:
		return null
	var enemy := (load("res://scenes/enemies/chaser.tscn") as PackedScene).instantiate() as EnemyActor
	enemy.position = point
	enemy.actor_id = _next_actor_id
	_next_actor_id += 1
	_actors.add_child(enemy)
	var stage: int = floori((state.current_level - 1) / 10.0)
	var hp_scale: float = 1.0 + 0.28 * stage + 0.025 * (state.current_level - 1)
	enemy.stats.max_hp *= hp_scale
	enemy.health.maximum = enemy.stats.max_hp
	enemy.health.current = enemy.stats.max_hp
	enemy.set_target(player)
	enemy.navigation = _arena.navigation_direction
	enemy.died.connect(_on_enemy_died)
	_enemies.append(enemy)
	var basic := load("res://content/skills/enemy_chaser_basic.tres") as SkillDefinition
	_enemy_attacks[enemy.actor_id] = AttackController.new(enemy, basic)
	enemy.stats.damage_multiplier = 1.0 + 0.15 * stage + 0.015 * (state.current_level - 1)
	return enemy

func _on_enemy_died(actor: Actor) -> void:
	kills += 1
	_enemy_attacks.erase(actor.actor_id)
	var enemy := actor as EnemyActor
	if state.alive:
		var orb := XpOrb.new()
		orb.configure(player, enemy.definition.xp_reward, _curve)
		orb.position = actor.global_position
		orb.collected.connect(progression.add_xp)
		_loot.add_child(orb)
	actor.queue_free()

func _on_level_applied(level: int) -> void:
	if not state.alive or not player.health.is_alive():
		return
	if level % 10 == 0: state.reroll_tokens = mini(3,state.reroll_tokens+1)
	_show_upgrade(level)

func _show_upgrade(level: int, excluded: Array[String] = []) -> void:
	_offer = OfferGenerator.generate_bound(_stat_cores, augments, skills, state.rng.stream(&"offers"),excluded)
	if _offer.size() != 3:
		push_error("Stat core catalog cannot produce three eligible options")
		get_tree().quit(1)
		return
	state.run_phase = &"UPGRADE"
	get_tree().paused = true
	var cards: Array[String] = []
	for option in _offer:
		cards.append(UiLocalizer.upgrade_label(option))
	presentation.show_offers(level, cards,state.reroll_tokens)
	_present_hud()

func request_reroll() -> void:
	if state.run_phase != &"UPGRADE" or not state.alive or state.reroll_tokens <= 0: return
	var previous: Array[String] = []
	for option in _offer: previous.append(option.key())
	state.reroll_tokens -= 1
	_show_upgrade(state.current_level,previous)

func request_upgrade(index: int) -> void:
	if state.run_phase != &"UPGRADE" or not state.alive or index < 0 or index >= _offer.size():
		return
	var option: UpgradeOption = _offer[index]
	if option.is_skill_rank:
		if not skills.upgrade_rank(option.slot): return
		state.run_upgrades[option.target_skill_id] = skills.runtime_for(option.slot).rank
	elif option.target_skill_id != &"":
		if not augments.apply_bound(option.definition, skills.runtime_for(option.slot)): return
		state.run_upgrades[StringName(option.key())] = augments.bound_rank(option.definition.id, option.target_skill_id)
	else:
		if not augments.apply(option.definition, player): return
		state.run_upgrades[option.definition.id] = augments.rank_for(option.definition.id)
	_offer.clear()
	presentation.hide_modal()
	state.run_phase = &"RUNNING"
	get_tree().paused = false
	if gate.request(state.current_level):
		progression.awaiting_choice = false
		state.xp_pending_during_boss += state.current_xp
		state.current_xp = 0
		_warning_left = 1.5
		presentation.announce("BOSS APPROACHING — find space to dodge!")
	else:
		progression.acknowledge_choice()
	_present_hud()

func _on_player_died(_actor: Actor) -> void:
	state.alive = false
	state.run_phase = &"DEAD"
	state.boss_gate_state = &"DEAD"
	_offer.clear()
	get_tree().paused = true
	presentation.show_message("RUN ENDED", tr("Level %d | Kills %d | Bosses %d | Maps %d\nTime %.1fs | Seed %d | Upgrades %d") % [state.current_level,kills,bosses_defeated,maps_visited,state.elapsed_simulation_seconds,state.seed,state.run_upgrades.size()], false)
	_present_hud()

func request_pause() -> void:
	if state.run_phase == &"RUNNING":
		state.run_phase = &"PAUSED"
		get_tree().paused = true
		presentation.show_message("PAUSED", "Combat simulation stopped.", true)
	elif state.run_phase == &"PAUSED":
		state.run_phase = &"RUNNING"
		get_tree().paused = false
		presentation.hide_modal()

func request_retry() -> void:
	if state.run_phase == &"RESTARTING":
		return
	state.run_phase = &"RESTARTING"
	get_tree().paused = false
	call_deferred("_retry_deferred")

func _retry_deferred() -> void:
	for child in _actors.get_children() + _loot.get_children():
		child.queue_free()
	combat.queue_free()
	await get_tree().process_frame
	_start_run()

func request_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/bootstrap/main.tscn")

func _present_hud() -> void:
	var settings := get_node("/root/AppSettings") as SettingsService
	presentation.hud.present(player.health.current, player.health.maximum, state.current_xp, _curve.threshold(state.current_level), state.current_level, state.seed, kills, _profile.display_name, settings.mode())
	presentation.hud.present_skills(skills, settings)
	presentation.hud.present_world(_arena.definition.display_name,boss,state.boss_gate_state,player)

func _change_map() -> void:
	if _map_bag.is_empty():
		_map_bag = [&"map.ruined_temple",&"map.enchanted_forest",&"map.volcanic_arena"]
		for i in range(_map_bag.size()-1,0,-1):
			var j: int = state.rng.stream(&"maps").randi_range(0,i)
			var value: StringName = _map_bag[i]
			_map_bag[i] = _map_bag[j]
			_map_bag[j] = value
		if _map_bag.back() == state.map_id: _map_bag.reverse()
	state.map_id = _map_bag.pop_back()
	var definition := (get_node("/root/ContentRegistry") as ContentRegistryService).definition_copy(state.map_id) as MapDefinition
	_arena.apply_layout(definition,MapLayoutGenerator.generate(definition,state.rng.stream(&"obstacles")))
	maps_visited += 1

func _spawn_boss() -> void:
	if not state.alive or state.boss_gate_state != &"PENDING": return
	var point: Variant = EnemySpawnDirector.sample(player.global_position,Rect2(),_arena,_spawn_config,state.rng.stream(&"spawns"),_enemies)
	if point == null or not _arena.spawn_clear(point,40):
		_warning_left = .5
		return
	if not gate.activate(): return
	boss = BossActor.new()
	var content_id: StringName = &"boss.stone_warden" if gate.milestone % 20 == 10 else &"boss.ember_sentinel"
	boss.boss_definition = (get_node("/root/ContentRegistry") as ContentRegistryService).definition_copy(content_id) as BossDefinition
	boss.combat = combat
	boss.actor_id = _next_actor_id
	_next_actor_id += 1
	boss.position = point
	boss.collision_layer = 2
	boss.collision_mask = 4
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 30
	shape.shape = circle
	boss.add_child(shape)
	_actors.add_child(boss)
	boss.set_target(player)
	boss.navigation = _arena.navigation_direction
	var stage: int = floori(gate.milestone/10.0)
	boss.health.maximum *= 1.0 + .45 * maxi(0,stage-2)
	boss.health.current = boss.health.maximum
	boss.stats.damage_multiplier = 1.0 + .25 * maxi(0,stage-2)
	boss.died.connect(_on_boss_died)
	boss.summon_requested.connect(func() -> void:
		for i in range(3):
			var minion: EnemyActor = spawn_enemy()
			if minion != null: minion.is_auxiliary = true)
	_enemies.append(boss)
	var attack := (load("res://content/skills/enemy_chaser_basic.tres") as SkillDefinition).duplicate(true) as SkillDefinition
	attack.rank_scaling[0].damage = boss.definition.damage
	attack.rank_scaling[0].range_px = 65
	_enemy_attacks[boss.actor_id] = AttackController.new(boss,attack)
	presentation.announce(tr(boss.boss_definition.display_name) + tr(" - dodge the orange warnings!"))

func _on_boss_died(actor: Actor) -> void:
	_enemy_attacks.erase(actor.actor_id)
	# End-of-frame adjudication gives player death priority over simultaneous victory.
	call_deferred("_resolve_boss_victory")

func _resolve_boss_victory() -> void:
	if not state.alive or not player.health.is_alive() or not gate.defeat(): return
	bosses_defeated += 1
	state.xp_pending_during_boss += boss.definition.xp_reward
	state.boss_gate_state = &"TRANSITIONING"
	state.run_phase = &"TRANSITIONING"
	for actor in _enemies:
		if is_instance_valid(actor): actor.queue_free()
	for orb in _loot.get_children(): orb.queue_free()
	combat.clear_transients()
	visual_factory.clear()
	_enemies.clear()
	_enemy_attacks.clear()
	boss = null
	player.clear_temporary()
	player.health.commit_resolved_hp(player.health.current + player.health.maximum*.15)
	for slot in range(1,5): skills.runtime_for(slot).advance_cooldown(1000000)
	_basic.cooldown_left = 0
	await get_tree().process_frame
	if not state.alive: return
	_change_map()
	player.position = _arena.definition.safe_spawn_anchor
	player.invulnerability_left = 2
	state.stage_index += 1
	gate.finish_transition()
	state.run_phase = &"RUNNING"
	_spawn_clock = 2
	presentation.announce("New map — 2s immunity. Upgrades kept; +15% HP; cooldowns reset.")
	var bank: int = state.xp_pending_during_boss
	state.xp_pending_during_boss = 0
	progression.add_xp(bank)
	_present_hud()

func _unhandled_input(event: InputEvent) -> void:
	if skills == null or state == null or state.run_phase != &"RUNNING" or not state.alive: return
	skills.set_mode((get_node("/root/AppSettings") as SettingsService).mode())
	if SkillInputRouter.handle(event, skills, player.global_position + player.facing * 1000): get_viewport().set_input_as_handled()


