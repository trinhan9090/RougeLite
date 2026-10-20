extends SceneTree
var checks: int=0
var failures: int=0
var packets: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func frames(count: int) -> void:
 for i in range(count):await physics_frame
 await process_frame
func run() -> void:
 AudioServer.set_bus_mute(0,true)
 for hero in ["astra","viridian","tofu","graveshade"]:
  for manual in [true,false]:
   var game: TrainingRun=(load("res://scenes/run/training_run.tscn") as PackedScene).instantiate()
   game.loadout_id=StringName("loadout."+hero);root.add_child(game)
   game.set_physics_process(false);game.player.set_physics_process(false)
   game.player.stats.crit_chance=0;game.player.record_attack_direction(Vector2.RIGHT)
   game.boss.position=game.player.position+Vector2(0,150)
   game.skills.candidates=[game.boss];game.skills.set_mode(&"MANUAL" if manual else &"AUTO")
   var slot: int=3 if hero=="astra" else 2
   for i in range(3):game.skills.upgrade_rank(slot)
   packets=0
   game.combat.resolver.events.damage_applied.connect(func(_context: CombatContext,result: DamageResult) -> void:
    if result.mitigated_damage>0:packets+=1)
   check(game.skills.request_cast(slot,Vector2.RIGHT*999 if manual else null),hero+" zone accepts cast")
   var zone_intent: CastIntent
   for child in game.combat.get_children():
    if child is TimedCombatEffect or child is MeleeSequenceRuntime or child is ControlMageRuntime or child is TacticalRuntime:zone_intent=child.intent
   check(zone_intent!=null and zone_intent.aim_point.is_equal_approx(game.boss.global_position),hero+" placement chooses off-axis Training boss in both modes")
   await frames(75)
   var early: int=packets
   await frames(120)
   check(packets>early and early>0,hero+" real damage continues over time on stationary immortal boss")
   check(game.boss.health.is_alive(),hero+" Training boss remains immortal")
   if zone_intent!=null:
    var original: Vector2=zone_intent.aim_point
    game.boss.position+=Vector2(15,0)
    check(zone_intent.aim_point==original,hero+" field stays fixed after cast")
   game.queue_free();await frames(3)
 print("RESULT ground zones: checks=",checks," failures=",failures)
 quit(failures)
