extends SceneTree
var checks: int=0
var failures: int=0
var actors: Array[Actor]=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func make_actor(id: int,point: Vector2) -> Actor:
 var a:=Actor.new();a.actor_id=id;a.team=2;a.stats_definition=ActorStatDefinition.new();a.position=point;root.add_child(a);actors.append(a);return a
func run() -> void:
 var owner:=PlayerActor.new();owner.actor_id=1;owner.stats_definition=ActorStatDefinition.new();root.add_child(owner);owner.set_physics_process(false)
 var combat:=CombatService.new();combat.rng=RunRng.new(55).stream(&"combat");root.add_child(combat);combat.actor_provider=func() -> Array[Actor]:return actors
 var near:=make_actor(2,Vector2(90,0));make_actor(3,Vector2(280,0));make_actor(4,Vector2(285,0))
 var ally:=make_actor(5,Vector2(5,0));ally.team=owner.team
 var dead:=make_actor(6,Vector2(10,0));dead.health.current=0
 var second:=make_actor(7,Vector2(0,180))
 var distant:=make_actor(8,Vector2(2000,0))
 var wall:=StaticBody2D.new();wall.collision_layer=4
 var shape:=CollisionShape2D.new();var rect:=RectangleShape2D.new();rect.size=Vector2(10,60);shape.shape=rect;wall.add_child(shape);wall.position=Vector2(45,0)
 for hero in ["astra","viridian","tofu","graveshade"]:
  var profile:=load("res://content/characters/"+hero+"_loadout.tres") as CombatLoadoutDefinition
  var slot: int=3 if hero=="astra" else 2
  for phase in [0,1,2]:
   for manual in [true,false]:
    combat.clear_transients();await process_frame
    owner.record_attack_direction(Vector2.RIGHT);owner.facing=Vector2.DOWN
    var controller:=SkillController.new(1,profile.active_skills);controller.bind(owner,combat);controller.sync_level(11)
    if phase<2:controller.candidates=actors
    else:controller.candidates.assign([ally,dead,distant])
    check(controller.request_cast(slot,Vector2.RIGHT if manual else null),hero+" accepts assisted placement")
    var intent: CastIntent
    for node in combat.get_children():
     if node is TimedCombatEffect or node is ControlMageRuntime or node is TacticalRuntime or node is MeleeSequenceRuntime:intent=node.intent
    var reach: float=controller.runtime_for(slot).effective_rank().range_px
    var expected: Vector2=near.position if phase==0 else second.position
    if phase==2:expected=(Vector2.RIGHT if manual else Vector2.DOWN)*reach
    check(intent!=null and intent.aim_point.is_equal_approx(expected),hero+" nearest excludes ally/dead, bypasses cluster, wall-aware and fallback phase"+str(phase))
   if phase==0:
    root.add_child(wall);await physics_frame;await physics_frame
   elif phase==1:
    root.remove_child(wall);await physics_frame
 wall.free();combat.free();owner.free()
 for actor in actors:actor.free()
 print("RESULT zone selection: checks=",checks," failures=",failures)
 quit(failures)
