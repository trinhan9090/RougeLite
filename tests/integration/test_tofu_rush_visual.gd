extends SceneTree
var failures: int=0
var checks: int=0
func _initialize() -> void:call_deferred("run")
func verify(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func run() -> void:
 var actor:=PlayerActor.new();actor.stats_definition=ActorStatDefinition.new();root.add_child(actor)
 actor.set_physics_process(false)
 var adapter:=MeleeActorEffects.new();root.add_child(adapter);adapter.actor=actor
 adapter.layer=Node2D.new();adapter.add_child(adapter.layer)
 adapter.sequences=JSON.parse_string(FileAccess.get_file_as_string("res://assets/private_tofu/effects.json"))
 for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
  var runtime:=Node.new();root.add_child(runtime)
  adapter._event({"kind":"melee_warning","skill":"skill.tofu.j","position":actor.global_position,"radius":80.0,"duration":.08,"direction":direction,"runtime":weakref(runtime)})
  verify(adapter.layer.get_child_count()==2,"J only warning plus source crescent, no stretched weapon")
  var rush:=adapter.layer.get_child(1) as MeleeVisualEffect
  rush.set_process(false)
  var source_size: Vector2=rush.textures[0].get_size()
  verify(is_equal_approx(rush.size_px.x/rush.size_px.y,source_size.x/source_size.y),"J retains source aspect")
  verify(is_equal_approx(rush.rotation,(direction as Vector2).angle()),"J follows accepted cast direction")
  actor.position+=Vector2(13,9);rush._process(.016)
  verify(rush.global_position.is_equal_approx(actor.global_position+actor.cast_origin_offset+direction*32),"J follows caster with forward offset")
  runtime.free();rush._process(.016)
  verify(rush.is_queued_for_deletion(),"J cancels source effect after dash runtime ends")
  adapter.clear();await process_frame
 verify(adapter.shown.get("weapon",0)==0,"no duplicate helper blade in any direction")
 adapter.free();actor.free()
 print("RESULT tofu J visual: checks=",checks," failures=",failures)
 quit(failures)
