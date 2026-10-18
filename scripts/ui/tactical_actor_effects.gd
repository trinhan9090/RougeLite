class_name TacticalActorEffects
extends Node2D
## Source-backed presentation. Every projectile/explosion is driven by actual runtime events.
var actor: PlayerActor
var combat: CombatService
var sequences: Dictionary
var layer: Node2D
var shown: Dictionary[String,int]={}
var count_limit: int=96
func configure(owner: PlayerActor,service: CombatService) -> void:
	actor=owner;combat=service
	sequences=JSON.parse_string(FileAccess.get_file_as_string(actor.visual_frames.get_meta("tactical_effects_profile")))
	layer=Node2D.new();add_child(layer);layer.set_as_top_level(true);layer.global_position=Vector2.ZERO
	combat.child_entered_tree.connect(_child)
	combat.visual_event.connect(_event)
	actor.health.depleted.connect(clear)
func _child(node: Node) -> void:
	if not node is CombatProjectile:return
	var projectile:=node as CombatProjectile
	if projectile._source.get_ref()!=actor:return
	_attach.call_deferred(weakref(projectile))
func _attach(ref: WeakRef) -> void:
	var projectile:=ref.get_ref() as CombatProjectile
	if not is_instance_valid(projectile) or projectile.is_queued_for_deletion():return
	for child in projectile.get_children():
		if child is CombatVisualEffect:(child as CanvasItem).hide()
	projectile.set_meta("art_bound",true)
	var rocket: bool=String(projectile._context.source_skill_id).ends_with(".i")
	var effect:=TacticalVisual.new();effect.sequence=sequences.rocket if rocket else sequences.bullet
	effect.size_px=Vector2(11,25) if rocket else Vector2(14,5);effect.persistent=true
	if rocket:effect.rotation=PI*.5
	projectile.add_child(effect);shown["rocket" if rocket else "bullet"]=shown.get("rocket" if rocket else "bullet",0)+1
	if not rocket and String(projectile._context.source_skill_id).ends_with(".basic"):_effect("muzzle",projectile.global_position,Vector2(12,10),.07).rotation=projectile._direction.angle()
func _effect(key: String,point: Vector2,size: Vector2,duration: float) -> TacticalVisual:
	if layer.get_child_count()>=count_limit:layer.get_child(0).free()
	var effect:=TacticalVisual.new();effect.sequence=sequences.get(key,[]);effect.size_px=size;effect.lifetime=duration
	layer.add_child(effect);effect.global_position=point
	shown[key]=shown.get(key,0)+1
	return effect
func _cue(key: StringName) -> void:
	if actor.action_audio!=null:actor.action_audio.play_cue(key)
func _event(event: Dictionary) -> void:
	if not String(event.get("skill","")).begins_with("skill.graveshade."):return
	var point: Vector2=event.position
	match event.kind:
		"fire_round":_effect("muzzle",point,Vector2(15,12),.07).rotation=(event.direction as Vector2).angle();_cue(&"round")
		"grenade_throw":
			var effect:=_effect("grenade",point,Vector2(9,9),event.duration)
			effect.ballistic=true;effect.arc_start=point;effect.arc_end=event.endpoint
			var warning:=_effect("",event.endpoint,Vector2.ZERO,event.duration);warning.warning_radius=event.radius
			_cue(&"throw")
		"mine_placed":
			var effect:=_effect("mine",point,Vector2(15,8),event.duration)
			effect.persistent=true;effect.mine=event.runtime;effect.z_index=-1
		"mine_armed":
			var warning:=_effect("",point,Vector2.ZERO,.15);warning.warning_radius=event.radius
			_cue(&"mine_arm")
		"rocket_warning":
			var effect:=_effect("",event.endpoint,Vector2.ZERO,event.duration);effect.warning_radius=event.radius
		"rocket_spawn":_effect("rocket_muzzle",point,Vector2(18,20),.15).rotation=(event.direction as Vector2).angle();_cue(&"rocket_launch")
		"explosion","rocket_explosion","mine_explosion","cluster":
			var key: String="mine_explosion" if event.kind=="mine_explosion" else "rocket_explosion" if event.kind in ["rocket_explosion","cluster"] else "explosion"
			# Keep the true damage boundary readable, with a smaller, shorter source blast.
			var boundary:=_effect("",point,Vector2.ZERO,.18);boundary.warning_radius=event.radius
			var blast:=_effect(key,point,Vector2.ONE*float(event.radius)*1.2,minf(event.duration,.24))
			blast.modulate.a=.8
			_cue(&"explosion")
		"burning_ground":
			var ground:=_effect("",point,Vector2.ZERO,event.duration)
			ground.ground_radius=event.radius;ground.z_index=-1
		"burn_tick":
			var pulse:=_effect("",point,Vector2.ZERO,.16);pulse.warning_radius=event.radius;pulse.modulate.a=.35
		"impact":_effect("impact",point,Vector2(12,12),.1)
func clear() -> void:
	if not is_instance_valid(layer):return
	for child in layer.get_children():child.queue_free()
