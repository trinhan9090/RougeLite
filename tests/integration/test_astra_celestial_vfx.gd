extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL ",label)
func frames(count: int = 2) -> void:
	for index in range(count): await process_frame
func find_effect(factory: CombatVisualFactory, kind: String) -> CelestialVisualEffect:
	for effect in factory.get_children():
		if effect is CelestialVisualEffect and effect.kind==kind: return effect
	return null
func run() -> void:
	var game := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(game)
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.audio.enabled = false
	game._arena.apply_layout(game._arena.definition,[])
	game.skills.sync_level(11)
	game.skills.set_mode(&"MANUAL")
	var factory: CombatVisualFactory = game.visual_factory
	for action: String in ["basic","j","k","l","i"]:
		check(factory.renderers.get("skill.astra."+action,"")=="pixel_v3","Astra "+action+" selects celestial renderer through data")
	for hero: String in ["vex","boros"]:
		for action: String in ["basic","j","k","l","i"]:
			check(factory.renderers.get("skill."+hero+"."+action,"")=="pixel_v3","roster character uses shared pixel renderer")
	var enemy: EnemyActor = game.spawn_enemy()
	check(enemy!=null,"real enemy spawned")
	if enemy==null: game.free(); quit(1); return
	enemy.position = Vector2(100,0)
	enemy.set_physics_process(false)
	enemy.health = Health.new(10000)
	check(game.skills.request_cast(2,Vector2(100,0)),"real K executor accepted")
	await frames()
	var dome: CelestialVisualEffect = find_effect(factory,"shield")
	check(dome!=null and dome.bound_shield!=null and dome.persistent,"K dome bound to actual ShieldInstance")
	if dome!=null:
		var actual_shield: ShieldInstance = game.player.health.shields.back()
		check(dome.bound_shield==actual_shield,"presentation reads the exact gameplay shield")
		check(game.player.get_meta("shield_visual").get_ref()==dome,"custom shell suppresses duplicate legacy shield rings")
		game.player.position = Vector2(80,60)
		await frames()
		check(dome.global_position.is_equal_approx(game.player.global_position),"K shell follows moving owner")
		var elapsed: float = dome.elapsed
		paused = true
		await frames(3)
		check(is_equal_approx(elapsed,dome.elapsed),"pause stops VFX phase")
		paused = false
		var strike := SkillRankDefinition.new()
		strike.damage = 90
		var result: DamageResult = game.combat.hit(enemy,game.player,strike,game.combat.next_context(enemy,&"test.break_shield"))
		check(result.accepted and actual_shield.remaining<=0,"real incoming damage breaks shield")
		await frames()
		check(dome.get_parent()!=factory,"broken shield immediately removes protective shell")
		check(not game.player.has_meta("shield_visual"),"shield cleanup releases owner presentation marker")
	game.player.position = Vector2.ZERO
	check(game.skills.request_cast(3,Vector2(150,0)),"real L executor accepted")
	await frames()
	var actual_area: TimedCombatEffect
	var rune: CelestialVisualEffect
	for node in game.combat.get_children():
		if node is TimedCombatEffect and node.executor.kind=="area":
			actual_area = node
			for child in node.get_children():
				if child is CelestialVisualEffect: rune = child
	check(actual_area!=null and rune!=null and rune.persistent,"L rune is a child of real timed area")
	if rune!=null:
		check(is_equal_approx(rune.radius,game.combat.modified_radius(actual_area.intent)),"L outer radius uses post-modifier geometry")
		check(rune.z_index<0,"ground rune stays below actors and hostile warnings")
	check(game.skills.request_cast(4,Vector2(200,0)),"real I executor accepted")
	var beam: CelestialVisualEffect = find_effect(factory,"beam")
	var rank: SkillRankDefinition = game.skills.runtime_for(4).effective_rank()
	check(beam!=null and is_equal_approx(beam.radius,rank.radius_px) and is_equal_approx(beam.line_end.length(),rank.range_px),"I beam envelope matches real damage width and length")
	var rune_id: int = rune.get_instance_id() if rune!=null else 0
	game.combat.clear_transients()
	await frames()
	check(not is_instance_id_valid(rune_id),"clearing gameplay area also releases persistent rune")
	factory.clear()
	for index in range(90):
		factory._on_event({"kind":"impact","skill":"skill.astra.j","position":Vector2.ZERO})
	check(factory.get_child_count()==80 and factory.dropped>=10,"decorative hard cap preserves bounded rendering")
	factory.clear()
	factory._on_event({"kind":"impact","skill":"skill.fixture.legacy","position":Vector2.ZERO})
	check(not factory.get_child(0) is CelestialVisualEffect,"pool never gives celestial art to another renderer")
	factory.clear()
	factory._on_event({"kind":"impact","skill":"skill.astra.basic","position":Vector2.ZERO})
	var recycled := factory.get_child(0) as CelestialVisualEffect
	check(recycled!=null and recycled.bound_shield==null and recycled.follow==null and not recycled.persistent,"pooled impact has no stale shield/owner/state")
	game.free()
	await frames()
	print("RESULT Astra celestial VFX checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
