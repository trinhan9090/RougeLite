class_name MeleeActorEffects
extends Node2D
## Source frames only. All spawning follows accepted gameplay events.
var actor: PlayerActor
var combat: CombatService
var sequences: Dictionary
var layer: Node2D
var shown: Dictionary[String,int]={}
func configure(owner: PlayerActor,service: CombatService) -> void:
	actor=owner;combat=service
	sequences=JSON.parse_string(FileAccess.get_file_as_string(actor.visual_frames.get_meta("melee_effects_profile")))
	layer=Node2D.new();add_child(layer);layer.set_as_top_level(true);layer.global_position=Vector2.ZERO
	combat.visual_event.connect(_event)
	actor.health.depleted.connect(clear)
func _effect(key: String,point: Vector2,size: Vector2,duration: float) -> MeleeVisualEffect:
	if layer.get_child_count()>=64:layer.get_child(0).free()
	var effect:=MeleeVisualEffect.new();effect.sequence=sequences.get(key,[]);effect.size_px=size;effect.lifetime=duration
	layer.add_child(effect);effect.global_position=point;shown[key]=shown.get(key,0)+1
	return effect
func _event(event: Dictionary) -> void:
	if not String(event.get("skill","")).begins_with("skill.tofu."):return
	var point: Vector2=event.position
	var slot: String=String(event.skill).get_slice(".",2)
	match event.kind:
		"melee_combo":
			var slash:=_effect("slash",point,Vector2.ONE*event.radius*1.4,.18);slash.rotation=(event.direction as Vector2).angle()
		"melee_warning":
			var warning:=_effect("",point,Vector2.ZERO,event.duration);warning.boundary_radius=event.radius
			if slot=="j":
				# Body AIR1300 already includes the weapon. AIR1301 is a thin
				# helper blade, not a90x100 overlay; stretching it creates a spike.
				var direction: Vector2=(event.direction as Vector2).normalized()
				var rush:=_effect("rush",point,Vector2(110,110),.95)
				if not rush.textures.is_empty():
					var source_size: Vector2=rush.textures[0].get_size()
					rush.size_px=source_size*(110.0/maxf(source_size.x,source_size.y))
				rush.rotation=direction.angle()
				rush.actor_offset=direction*32
				rush.actor_ref=weakref(actor);rush.runtime_ref=event.runtime
				rush.global_position=actor.global_position+actor.cast_origin_offset+rush.actor_offset
		"melee_strike":
			var hit:=_effect("chain" if slot=="l" else "slash",point,Vector2.ONE*event.radius*1.4,event.duration);hit.rotation=(event.direction as Vector2).angle()
		"melee_slam":_effect("slam",point,Vector2.ONE*event.radius*1.6,.28)
		"melee_field":
			var field:=_effect("",point,Vector2.ZERO,event.duration);field.boundary_radius=event.radius;field.ground=true;field.z_index=-1;field.runtime_ref=event.runtime
			for index in range(5):
				var debris:=_effect("debris",point+Vector2.from_angle(index*TAU/5)*float(event.radius)*.6,Vector2(18,24),event.duration)
				debris.modulate.a=.45;debris.z_index=-1;debris.runtime_ref=event.runtime
		"melee_nuke":
			# AIR6550 embeds a fighter silhouette: do not overlay a second body.
			var burst:=_effect("nuke",point,Vector2(125,125),event.duration)
			burst.complete_once=true
			burst.size_px=Vector2(125,125*618.0/674.0)
		"impact":_effect("slash",point,Vector2(22,22),.10)
func clear() -> void:
	if not is_instance_valid(layer):return
	for node in layer.get_children():node.queue_free()
