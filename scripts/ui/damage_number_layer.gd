class_name DamageNumberLayer
extends Node2D
## Pooled floating damage captions. Instances are reused so heavy fights do not
## allocate a Label per hit.
var combat: CombatService
var displayed: int=0
const LIMIT: int=128
var _pool: Array[FloatingDamageNumber] = []
func _ready() -> void:
	z_index=30
	combat.visual_event.connect(_on_event)
func _on_event(event: Dictionary) -> void:
	if event.kind!="damage_number": return
	var number := _borrow()
	number.setup(float(event.amount),bool(event.critical),event.get("follow",null),float(event.get("height",48)),((displayed%5)-2)*5,event.position)
	displayed+=1
## Reuse a pooled instance, recycle the oldest live one, or create a new one.
func _borrow() -> FloatingDamageNumber:
	if not _pool.is_empty():
		var pooled: FloatingDamageNumber = _pool.pop_back()
		add_child(pooled)
		return pooled
	if get_child_count() >= LIMIT:
		var oldest := get_child(0) as FloatingDamageNumber
		if oldest != null:
			oldest.set_process(false)
			remove_child(oldest)
			add_child(oldest)
			return oldest
	var created := FloatingDamageNumber.new()
	created.expired.connect(_on_expired)
	add_child(created)
	return created
func _on_expired(number: FloatingDamageNumber) -> void:
	if number.get_parent()!=self: return
	remove_child(number)
	number.set_process(false)
	if _pool.size()<LIMIT:
		_pool.append(number)
	else:
		number.free()
func clear() -> void:
	for node in get_children(): node.free()
	for node in _pool: node.free()
	_pool.clear()
func _exit_tree() -> void:
	for node in _pool: node.free()
	_pool.clear()
