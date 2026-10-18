class_name CombatVisualFactory
extends Node2D
## Per-run presentation sibling: never consumes combat child/projectile budgets or RNG.
var combat: CombatService
var colors: Dictionary = {}
var styles: Dictionary = {}
var renderers: Dictionary = {}
var accepted_events: Dictionary[String,int] = {}
var dropped: int = 0
var trails: int = 0
const LIMIT: int = 80
var _pool: Array[CombatVisualEffect] = []
var _pixel_mode: bool = false
var _status_targets: Dictionary[int,WeakRef] = {}
func _ready() -> void:
	for file in DirAccess.get_files_at("res://assets/vfx/generated"):
		if not file.ends_with(".json"): continue
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/vfx/generated/"+file))
		var parameters: Dictionary = manifest.parameters
		colors[String(parameters.skill_id)] = Color(parameters.color)
		styles[String(parameters.skill_id)] = parameters.style
		renderers[String(parameters.skill_id)] = parameters.get("renderer","")
	_pixel_mode = renderers.values().has("pixel_v3")
	combat.visual_event.connect(_on_event)
	combat.child_entered_tree.connect(_on_child)
func _on_child(node: Node) -> void:
	if node is CombatFlash or node is TimedCombatEffect: node.set_meta("art_bound",true)
	if node is CombatProjectile:
		_attach_projectile.call_deferred(weakref(node))
	if node is TimedCombatEffect:
		_attach_area.call_deferred(weakref(node))
func _attach_area(reference: WeakRef) -> void:
	var node := reference.get_ref() as TimedCombatEffect
	if not is_instance_valid(node) or node.is_queued_for_deletion() or node.executor.kind not in ["area","dash"]: return
	if renderers.get(String(node.intent.context.source_skill_id),"") not in ["celestial","pixel_v3"]: return
	var effect: CelestialVisualEffect = PixelVisualEffect.new() if _pixel_mode else CelestialVisualEffect.new()
	effect.kind = "area" if node.executor.kind=="area" else "dash"
	if node.executor.kind=="dash": effect.rotation=node.intent.direction.angle()
	effect.style = styles.get(String(node.intent.context.source_skill_id),"")
	effect.color = colors.get(String(node.intent.context.source_skill_id),Color.CYAN)
	effect.radius = combat.modified_radius(node.intent)
	effect.persistent = true
	effect.z_index = -1
	node.add_child(effect)
func _attach_projectile(reference: WeakRef) -> void:
	var projectile := reference.get_ref() as CombatProjectile
	if not is_instance_valid(projectile) or projectile.is_queued_for_deletion() or trails >= 120: return
	trails += 1
	var celestial: bool = renderers.get(String(projectile._context.source_skill_id),"")in ["celestial","pixel_v3"]
	var effect: CombatVisualEffect = (PixelVisualEffect.new() if _pixel_mode else CelestialVisualEffect.new()) if celestial else CombatVisualEffect.new()
	effect.kind = "projectile"
	effect.style = styles.get(String(projectile._context.source_skill_id),"")
	effect.color = colors.get(String(projectile._context.source_skill_id),Color("d0e5e5"))
	effect.persistent = true
	effect.radius = projectile._rank.radius_px
	effect.tree_exiting.connect(_release_trail)
	projectile.set_meta("art_bound",true)
	projectile.add_child(effect)
	if celestial:
		_on_event({"kind":"cast","skill":projectile._context.source_skill_id,"position":projectile.global_position,"angle":projectile._direction.angle(),"radius":13.0,"duration":.12})

func _borrow_effect(celestial: bool) -> CombatVisualEffect:
	for index in range(_pool.size()):
		if (_pool[index] is CelestialVisualEffect)==celestial:
			var effect: CombatVisualEffect = _pool[index]
			_pool.remove_at(index)
			return effect
	# Replace an idle instance of the other renderer rather than allowing it to
	# occupy this renderer's pool capacity indefinitely.
	if not _pool.is_empty():
		var obsolete: CombatVisualEffect = _pool.pop_back()
		obsolete.free()
	var created: CombatVisualEffect = (PixelVisualEffect.new() if _pixel_mode else CelestialVisualEffect.new()) if celestial else CombatVisualEffect.new()
	created.pooled = true
	created.finished.connect(_recycle)
	return created
func _on_event(event: Dictionary) -> void:
	var kind: String = event.kind
	if kind=="damage_number": return # separate presentation layer and budget
	accepted_events[kind] = accepted_events.get(kind,0)+1
	if get_child_count() >= LIMIT:
		dropped += 1
		return
	if kind == "status":
		var key: int = int(event.get("target_id",0))
		if _status_targets.has(key) and is_instance_valid(_status_targets[key].get_ref()): return
	var celestial: bool = renderers.get(String(event.get("skill","")),"")in ["celestial","pixel_v3"]
	var effect: CombatVisualEffect = _borrow_effect(celestial)
	effect.kind = kind
	effect.style = styles.get(String(event.get("skill","")),"")
	effect.color = colors.get(String(event.get("skill","")),Color("c8d9dd"))
	effect.radius = float(event.get("radius",20))
	effect.line_end = event.get("line_end",Vector2.ZERO)
	effect.duration = float(event.get("duration",.3))
	effect.remaining = effect.duration
	effect.elapsed = 0
	effect.persistent = false
	effect.follow = event.get("follow",null)
	if not celestial and event.has("shield_instance"): effect.follow = null
	effect.z_index = -1 if celestial and kind=="area" else 0
	if effect is CelestialVisualEffect:
		effect.bound_shield = event.get("shield_instance",null) as ShieldInstance
		if effect.bound_shield != null:
			effect.persistent = true
			effect.radius = 48
			effect.shield_capacity = maxf(1,effect.bound_shield.remaining)
	if effect is PixelVisualEffect:
		effect.bound_buff=StringName(event.get("buff_id",&""))
		if effect.bound_buff!=&"": effect.persistent=true;effect.z_index=-1
	effect.set_process(true)
	effect.show()
	effect.modulate = Color(1,1,1,.4) if celestial and get_child_count()>=25 else Color.WHITE
	if kind == "status": _status_targets[int(event.get("target_id",0))] = weakref(effect)
	add_child(effect)
	effect.global_position = event.position
	effect.rotation = float(event.get("angle",0))
	if effect is CelestialVisualEffect and effect.bound_shield!=null and effect.follow!=null:
		var owner_actor := effect.follow.get_ref() as Actor
		if is_instance_valid(owner_actor):
			owner_actor.set_meta("shield_visual",weakref(effect))
			owner_actor.queue_redraw()
func clear() -> void:
	for child in get_children(): _recycle(child as CombatVisualEffect)
	_status_targets.clear()
func _recycle(effect: CombatVisualEffect) -> void:
	if effect.get_parent()!=self: return
	if effect.kind == "status":
		for key: int in _status_targets.keys():
			if _status_targets[key].get_ref()==effect: _status_targets.erase(key)
	remove_child(effect)
	effect.set_process(false)
	effect.hide()
	if effect.follow!=null:
		var owner_actor := effect.follow.get_ref() as Actor
		if is_instance_valid(owner_actor):
			var shell: WeakRef = owner_actor.get_meta("shield_visual") as WeakRef if owner_actor.has_meta("shield_visual") else null
			if shell!=null and shell.get_ref()==effect: owner_actor.remove_meta("shield_visual")
			owner_actor.queue_redraw()
	effect.follow = null
	if effect is CelestialVisualEffect: effect.bound_shield = null
	if effect is PixelVisualEffect: effect.bound_buff=&""
	if _pool.size()<LIMIT: _pool.append(effect)
	else: effect.free()
func _exit_tree() -> void:
	for effect in _pool: effect.free()
	_pool.clear()
func _release_trail() -> void:
	trails = maxi(0,trails-1)
