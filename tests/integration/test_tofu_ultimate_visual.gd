extends SceneTree
var failures: int=0
func _initialize() -> void:call_deferred("run")
func verify(ok: bool,label: String) -> void:
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func run() -> void:
 var adapter:=MeleeActorEffects.new()
 root.add_child(adapter)
 adapter.layer=Node2D.new();adapter.add_child(adapter.layer)
 adapter.sequences=JSON.parse_string(FileAccess.get_file_as_string("res://assets/private_tofu/effects.json"))
 adapter._event({"kind":"melee_nuke","skill":"skill.tofu.i","position":Vector2(70,-36),"duration":.4,"direction":Vector2.RIGHT})
 verify(adapter.layer.get_child_count()==1,"I creates one slash, no embedded fighter silhouette")
 var effect:=adapter.layer.get_child(0) as MeleeVisualEffect
 effect.set_process(false)
 verify(effect.global_position==Vector2(70,-36),"impact stays at actual target torso")
 verify(is_equal_approx(effect.size_px.x/effect.size_px.y,674.0/618.0),"source aspect ratio preserved")
 effect._process(.2)
 verify(effect._frame==26,"half duration reaches source middle frame")
 effect._process(.199)
 verify(effect._frame==51,"final source frame reached before expiry")
 effect._process(.002)
 verify(effect.is_queued_for_deletion(),"impact cleans up without replay")
 adapter.free()
 print("TOFU I VISUAL: 6 checks, ",failures," failures")
 quit(failures)
