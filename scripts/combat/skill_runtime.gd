class_name SkillRuntime
extends RefCounted
## Per-actor lifecycle state. Cast execution/targeting are controller concerns.
## Definitions and effective rank reads are detached snapshots.

var _definition: SkillDefinition
var _owner_id: int
var _rank: int = 0
var _cooldown: float = 0.0
var _sequence: int = 0
var _valid: bool = false
var _owner_ref: WeakRef

func bind_owner(owner: Actor) -> bool:
	if not is_instance_valid(owner) or owner.actor_id != _owner_id: return false
	_owner_ref = weakref(owner)
	return true

func owner_alive() -> bool:
	if _owner_ref == null: return true # Lifecycle/content-only fixtures are unbound.
	var owner: Actor = _owner_ref.get_ref() as Actor
	return is_instance_valid(owner) and not owner.is_queued_for_deletion() and owner.health.is_alive()

var rank: int:
	get: return _rank

var cooldown_remaining: float:
	get: return _cooldown

var cast_sequence_number: int:
	get: return _sequence

var owner_actor_id: int:
	get: return _owner_id

var definition: SkillDefinition:
	get: return _definition.duplicate(true) as SkillDefinition if _definition != null else null

func _init(source: SkillDefinition, actor_id: int) -> void:
	_owner_id = actor_id
	if source != null and source.validate().is_empty() and actor_id > 0:
		_definition = source.duplicate(true) as SkillDefinition
		_valid = true

func valid() -> bool:
	return _valid

func unlock_for_level(level: int) -> bool:
	if not _valid or _rank > 0 or level < _definition.unlock_level:
		return false
	_rank = 1
	return true

func upgrade_rank() -> bool:
	if not _valid or not owner_alive() or _rank == 0 or _rank >= _definition.max_rank:
		return false
	_rank += 1
	return true

func effective_rank() -> SkillRankDefinition:
	if not _valid or _rank == 0:
		return null
	return _definition.rank_scaling[_rank - 1].duplicate(true) as SkillRankDefinition

func has_capability(capability: StringName) -> bool:
	return _valid and _definition.declared_capabilities.has(capability) and _definition.executor.supported_capabilities().has(capability)

func cooldown_ready() -> bool:
	return _valid and _rank > 0 and _cooldown <= 0.0

func commit_cast(cooldown_reduction: float = 0.0) -> bool:
	# Called only AFTER an executor accepts a cast in the later cast pipeline.
	# This method commits lifecycle state; it does not execute an ability.
	if not cooldown_ready() or not is_finite(cooldown_reduction):
		return false
	_cooldown = _definition.rank_scaling[_rank - 1].cooldown * (1.0 - clampf(cooldown_reduction, 0.0, 0.6))
	_sequence += 1
	return true

func advance_cooldown(delta: float, simulation_active: bool = true) -> void:
	if simulation_active and is_finite(delta) and delta > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)

func refund_base_fraction(fraction: float) -> void:
	if _valid and _rank > 0:
		_cooldown = maxf(0, _cooldown - _definition.rank_scaling[_rank - 1].cooldown * clampf(fraction, 0, 1))
