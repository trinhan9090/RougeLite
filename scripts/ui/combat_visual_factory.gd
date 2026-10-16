class_name CombatVisualFactory
extends Node2D
## Per-run presentation sibling: never consumes combat child/projectile budgets or RNG.
var combat: CombatService
var colors: Dictionary = {}
var styles: Dictionary = {}
var accepted_events: Dictionary[String,int] = {}
var dropped: int = 0
var trails: int = 0
const LIMIT: int = 80
func _ready() -> void:
	for file in DirAccess.get_files_at("res://assets/vfx/generated"):
		if not file.ends_with(".json"): continue
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/vfx/generated/"+file))
		var parameters: Dictionary = manifest.parameters
		colors[String(parameters.skill_id)] = Color(parameters.color)
		styles[String(parameters.skill_id)] = parameters.style
	combat.visual_event.connect(_on_event)
	combat.child_entered_tree.connect(_on_child)
func _on_child(node: Node) -> void:
	if node is CombatFlash or node is TimedCombatEffect: node.set_meta("art_bound",true)
	if node is CombatProjectile:
		_attach_projectile.call_deferred(weakref(node))
func _attach_projectile(reference: WeakRef) -> void:
	var projectile := reference.get_ref() as CombatProjectile
	if not is_instance_valid(projectile) or projectile.is_queued_for_deletion() or trails >= 120: return
	trails += 1
	var effect := CombatVisualEffect.new()
	effect.kind = "projectile"
	effect.style = styles.get(String(projectile._context.source_skill_id),"")
	effect.color = colors.get(String(projectile._context.source_skill_id),Color("d0e5e5"))
	effect.persistent = true
	effect.tree_exiting.connect(_release_trail)
	projectile.set_meta("art_bound",true)
	projectile.add_child(effect)
func _on_event(event: Dictionary) -> void:
	var kind: String = event.kind
	accepted_events[kind] = accepted_events.get(kind,0)+1
	if get_child_count() >= LIMIT:
		dropped += 1
		return
	var effect := CombatVisualEffect.new()
	effect.kind = kind
	effect.style = styles.get(String(event.get("skill","")),"")
	effect.color = colors.get(String(event.get("skill","")),Color("c8d9dd"))
	effect.radius = float(event.get("radius",20))
	effect.line_end = event.get("line_end",Vector2.ZERO)
	effect.duration = float(event.get("duration",.3))
	effect.remaining = effect.duration
	add_child(effect)
	effect.global_position = event.position
	effect.rotation = float(event.get("angle",0))
func clear() -> void:
	for child in get_children(): child.queue_free()
func _release_trail() -> void:
	trails = maxi(0,trails-1)
