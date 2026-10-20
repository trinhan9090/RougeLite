class_name MappedActorEffects
extends Node2D
## Local presentation adapter; no hitboxes, targeting or damage logic.
var actor: PlayerActor
var combat: CombatService
var sequences: Dictionary
var bolt_size: Vector2 = Vector2(28,14)
var basic_impact_size: float = 20
## Opt-in layered bolt composite (see MappedSpriteEffect.bolt_layers).
var bolt_layers: bool = false
## Core shape for the layered composite: "bar" or "dot".
var bolt_core: String = "bar"
var skills: Dictionary
var shown: Dictionary[String,int] = {}
var _layer: Node2D

func configure(source: PlayerActor,service: CombatService) -> void:
	actor=source;combat=service
	var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(actor.visual_frames.get_meta("mapped_effects_profile")))
	sequences=JSON.parse_string(FileAccess.get_file_as_string(config.sequences))
	skills=config.skills
	var dimensions: Array=config.get("bolt_size",[28,14])
	bolt_size=Vector2(float(dimensions[0]),float(dimensions[1]))
	basic_impact_size=float(config.get("basic_impact_size",20))
	bolt_layers=bool(config.get("bolt_layers",false))
	bolt_core=String(config.get("bolt_core","bar"))
	_layer=Node2D.new()
	# Presentation children are outside CombatService projectile-node budget.
	add_child(_layer)
	_layer.set_as_top_level(true)
	_layer.global_position=Vector2.ZERO
	combat.child_entered_tree.connect(_on_child)
	combat.visual_event.connect(_on_event)

func _on_child(node: Node) -> void:
	if node is CombatProjectile:
		var projectile := node as CombatProjectile
		if projectile._source.get_ref()!=actor or not skills.has(String(projectile._context.source_skill_id)):return
		_attach_bolt.call_deferred(weakref(projectile))

func _attach_bolt(ref: WeakRef) -> void:
	var node := ref.get_ref() as CombatProjectile
	if not is_instance_valid(node) or node.is_queued_for_deletion():return
	_hide_default_visuals(node)
	# Defensive: the shared factory also attaches a default visual via its own
	# deferred call; hide any CombatVisualEffect added after us as well.
	if not node.has_meta("mapped_hide_connected"):
		node.set_meta("mapped_hide_connected",true)
		node.child_entered_tree.connect(_hide_default_visuals.bind(node))
	node.set_meta("art_bound",true)
	var effect := MappedSpriteEffect.new()
	effect.sequence=sequences.bolt;effect.persistent=true;effect.size_px=bolt_size
	effect.bolt_layers=bolt_layers
	effect.bolt_core=bolt_core
	node.add_child(effect)
	shown["bolt"]=shown.get("bolt",0)+1

func _hide_default_visuals(node: Node) -> void:
	for child in node.get_children():
		if child is CombatVisualEffect:
			(child as CanvasItem).hide()

func _on_event(event: Dictionary) -> void:
	var key: String=String(event.get("skill",""))
	if not skills.has(key):return
	if event.kind=="cast" and skills[key]=="cataclysm":
		var warning:=MappedSpriteEffect.new()
		warning.size_px=Vector2((event.line_end as Vector2).length(),0)
		warning.fan_degrees=70;warning.lifetime=event.duration;warning.follow=event.get("runtime")
		_layer.add_child(warning);warning.global_position=event.position;warning.rotation=(event.line_end as Vector2).angle()
	elif event.kind=="cast" and skills[key]=="lance":
		var length: Vector2=event.line_end
		var warning: MappedSpriteEffect=_effect("beam",event.position+length*.5,Vector2(length.length(),float(event.radius)*2),event.duration)
		warning.modulate.a=.25;warning.rotation=length.angle()
	elif event.kind=="beam":
		var length: Vector2=event.line_end
		var effect: MappedSpriteEffect=_effect("ultimate" if skills[key]=="cataclysm" else "beam",event.position+length*.5,Vector2(length.length(),float(event.radius)*2),.18)
		effect.rotation=length.angle()
		effect.caster=weakref(actor);effect.cancel_on_stun=skills[key]=="cataclysm"
		effect.show_lane_boundary=skills[key]=="cataclysm"
		if skills[key]!="cataclysm" and actor.action_audio!=null:actor.action_audio.play_cue(&"beam")
	elif event.kind=="impact": _effect("bolt",event.position,Vector2.ONE*(basic_impact_size if skills[key]=="bolt" else 20),.12)

func _effect(sequence_name: String,point: Vector2,size: Vector2,duration: float) -> MappedSpriteEffect:
	if _layer.get_child_count()>=96: _layer.get_child(0).free()
	var effect := MappedSpriteEffect.new()
	effect.sequence=sequences[sequence_name];effect.size_px=size;effect.lifetime=duration
	_layer.add_child(effect);effect.global_position=point
	shown[sequence_name]=shown.get(sequence_name,0)+1
	return effect

func show_effect(kind: String,point: Vector2,radius: float,duration: float,runtime: ControlMageRuntime) -> void:
	if kind=="orbit":
		for index in range(runtime.intent.rank.projectile_count):
			var effect: MappedSpriteEffect=_effect("orb",point,Vector2(18,18),duration)
			effect.follow=weakref(runtime);effect.orbit_index=index
			effect.global_position=point+Vector2.from_angle(index*TAU/runtime.intent.rank.projectile_count)*radius
	elif kind=="prison":
		var effect: MappedSpriteEffect=_effect("prison",point,Vector2.ONE*radius*2,duration)
		effect.follow=weakref(runtime);effect.z_index=-1
	elif kind=="prison_warning":
		var effect: MappedSpriteEffect=_effect("prison",point,Vector2.ONE*radius*2,duration)
		effect.modulate.a=.35;effect.z_index=-1

func clear() -> void:
	for child in _layer.get_children():child.free()
