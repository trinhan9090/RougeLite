extends SceneTree
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func area(game: CombatRunRoot) -> TimedCombatEffect:
	for child in game.combat.get_children():
		if child is TimedCombatEffect and child.executor.kind=="area" and not child.is_queued_for_deletion():return child
	return null
func run() -> void:
	var game := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(game)
	game.set_physics_process(false);game.player.set_physics_process(false)
	game._arena.apply_layout(game._arena.definition,[])
	game.skills.sync_level(11)
	game.player.position=Vector2.ZERO
	game.player.facing=Vector2.LEFT
	var near: EnemyActor=game.spawn_enemy()
	var far: EnemyActor=game.spawn_enemy()
	near.set_physics_process(false);far.set_physics_process(false)
	near.position=Vector2(100,60);far.position=Vector2(-200,0)
	near.health=Health.new(10000);far.health=Health.new(10000)
	game.skills.candidates=[far,near]
	for mode: StringName in [&"MANUAL",&"AUTO"]:
		game.skills.set_mode(mode)
		game.skills.runtime_for(3).advance_cooldown(1000)
		check(game.skills.request_cast(3,Vector2(-350,0) if mode==&"MANUAL" else null),"L nearest accepted "+String(mode))
		var field: TimedCombatEffect=area(game)
		check(field!=null and field.global_position.is_equal_approx(near.position),"L chooses closer enemy even behind facing "+String(mode))
		game.combat.clear_transients();await process_frame
	near.position=Vector2(500,0);far.position=Vector2(-700,0)
	game.player.record_attack_direction(Vector2.LEFT)
	for mode: StringName in [&"MANUAL",&"AUTO"]:
		game.skills.set_mode(mode)
		game.skills.runtime_for(3).advance_cooldown(1000)
		check(game.skills.request_cast(3,Vector2.RIGHT*999 if mode==&"MANUAL" else null),"L out of range fallback accepted "+String(mode))
		var field: TimedCombatEffect=area(game)
		check(field!=null and field.global_position.is_equal_approx(Vector2(-350,0)),"L fallback exactly max range along facing "+String(mode))
		game.combat.clear_transients();await process_frame
	near.position=Vector2(50,0);near.team=game.player.team
	game.skills.candidates=[near]
	game.skills.runtime_for(3).advance_cooldown(1000)
	check(game.skills.request_cast(3),"friendly-only scene permits fallback")
	check(area(game).position.is_equal_approx(Vector2(-350,0)),"friendly never selected")
	game.combat.clear_transients();await process_frame
	near.team=2;near.position=Vector2(150,0)
	game.skills.candidates=[near]
	game.skills.set_mode(&"AUTO")
	check(game.player.cast_origin_offset==Vector2(0,-12),"Astra origin from loadout at hand/body center")
	game._basic.cooldown_left=0
	check(game._basic.step(0,[near],game.combat),"actual basic accepted")
	var projectile: CombatProjectile
	for child in game.combat.get_children():
		if child is CombatProjectile:projectile=child;break
	check(projectile!=null and projectile.position.is_equal_approx(Vector2(0,-12)),"actual projectile leaves hand rather than feet")
	if projectile!=null:
		check(projectile._direction.is_equal_approx(Vector2(0,-12).direction_to(near.hit_position())),"basic trajectory aims from actual origin")
		await process_frame
		check(projectile.get_child_count()==1 and projectile.get_child(0) is PixelVisualEffect,"one visual attached to actual projectile")
	game.combat.clear_transients();await process_frame
	game.skills.set_mode(&"MANUAL");game.player.facing=Vector2.RIGHT
	var j_hp: float=near.health.current
	check(game.skills.request_cast(1,Vector2.RIGHT*620),"Manual J accepted along facing")
	for i in range(20):await physics_frame
	check(near.health.current<j_hp,"Manual J still hits an enemy directly along facing from hand origin")
	game.combat.clear_transients();await process_frame
	var seen: Array[Dictionary]=[]
	game.combat.visual_event.connect(func(event: Dictionary) -> void:
		if event.kind=="beam":seen.append(event))
	game.skills.runtime_for(4).advance_cooldown(1000)
	var hp: float=near.health.current
	check(game.skills.request_cast(4,Vector2.RIGHT*600),"actual beam accepted")
	check(seen.size()==1 and seen[0].position.is_equal_approx(Vector2(0,-12)),"beam VFX uses same real hand origin")
	check(near.health.current<hp,"beam damage still hits its actual envelope")
	check(is_equal_approx(seen[0].line_end.length(),600),"beam range preserved")
	var wall := StaticBody2D.new();wall.collision_layer=4
	wall.position=Vector2(0,-8)
	var shape := CollisionShape2D.new();var box := RectangleShape2D.new();box.size=Vector2(60,4);shape.shape=box;wall.add_child(shape);root.add_child(wall)
	await physics_frame;await physics_frame
	check(game.combat.cast_origin(game.player).y>-6,"origin cannot teleport through adjacent wall")
	wall.free();game.free();await process_frame
	print("RESULT Astra cast corrections checks=%d failures=%d"%[checks,failures])
	quit(0 if failures==0 else 1)
