extends SceneTree
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run() -> void:
	var game := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	root.add_child(game);game.set_physics_process(false);game.player.set_physics_process(false)
	game._arena.apply_layout(game._arena.definition,[])
	var e: EnemyActor=game.spawn_enemy();e.set_physics_process(false);e.position=Vector2(100,0);e.health=Health.new(10000)
	check(e.hurtbox!=null and e.hurtbox.position==Vector2(0,-18),"torso capsule centered above feet")
	check((e.get_node("CollisionShape2D").shape as CircleShape2D).radius==13,"locomotion collider preserved")
	await physics_frame;await physics_frame
	for row: Array in [[-25.0,true],[8.0,false]]:
		var rank := game._profile.basic_attack.rank_scaling[0].duplicate(true) as SkillRankDefinition
		rank.behavior=null
		var p := CombatProjectile.new();var c: CombatContext=game.combat.next_context(game.player,&"test.hurtbox")
		p.configure_direction(game.combat,game.player,e,rank,c,Vector2.RIGHT,0,null)
		game.combat.add_child(p);p.position=Vector2(0,row[0])
		var hp: float=e.health.current
		for i in range(14):await physics_frame
		check((e.health.current<hp)==row[1],"upper torso hits; foot-only ground pass does not")
		game.combat.clear_transients();await process_frame
	var events: Array[Dictionary]=[]
	game.combat.visual_event.connect(func(event: Dictionary)->void:
		if event.kind=="impact":events.append(event))
	var rank := SkillRankDefinition.new();rank.damage=1;rank.behavior=SkillBehaviorDefinition.new();rank.behavior.can_crit=false
	game.combat.hit(game.player,e,rank,game.combat.next_context(game.player,&"test.impact"))
	check(events.size()==1 and events[0].position==e.hit_position(),"impact spark placed on torso")
	check(TargetingService.intercept_point(Vector2.ZERO,e,600)==e.hit_position(),"stationary aim targets torso")
	check(game.combat.beam_receivers(game.player,Vector2(0,-25),Vector2.RIGHT,200,2).has(e),"beam intersects upper torso")
	check(not game.combat.beam_receivers(game.player,Vector2(0,8),Vector2.RIGHT,200,2).has(e),"beam rejects locomotion-only intersection")
	var second:EnemyActor=game.spawn_enemy();second.set_physics_process(false);second.position=Vector2(180,0);second.health=Health.new(10000)
	await physics_frame;await physics_frame
	var piercing:SkillRankDefinition=game._profile.basic_attack.rank_scaling[0].duplicate(true)
	piercing.behavior=null;piercing.pierce_count=1;piercing.projectile_speed=900
	var first_hp:float=e.health.current
	var shot:=CombatProjectile.new();shot.configure_direction(game.combat,game.player,e,piercing,game.combat.next_context(game.player,&"test.pierce"),Vector2.RIGHT,0,null)
	game.combat.add_child(shot);shot.position=Vector2(0,-25)
	for f:int in range(20):await physics_frame
	check(e.health.current<first_hp and second.health.current<10000,"pierce reaches two actual torso receivers")
	game.combat.clear_transients();await process_frame
	var wall:=StaticBody2D.new();wall.collision_layer=4;wall.position=Vector2(60,-15)
	var shape:=CollisionShape2D.new();var rectangle:=RectangleShape2D.new();rectangle.size=Vector2(12,70);shape.shape=rectangle;wall.add_child(shape);game.add_child(wall)
	await physics_frame;await physics_frame
	check(not game.combat.beam_receivers(game.player,Vector2(0,-25),Vector2.RIGHT,200,2).has(e),"wall blocks torso beam")
	first_hp=e.health.current
	shot=CombatProjectile.new();shot.configure_direction(game.combat,game.player,e,piercing,game.combat.next_context(game.player,&"test.wall"),Vector2.RIGHT,0,null)
	game.combat.add_child(shot);shot.position=Vector2(0,-25)
	for f:int in range(20):await physics_frame
	check(e.health.current==first_hp,"wall blocks torso projectile")
	game.free();await process_frame
	print("RESULT torso hurtbox checks=%d failures=%d"%[checks,failures]);quit(0 if failures==0 else 1)
