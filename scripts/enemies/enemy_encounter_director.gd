class_name EnemyEncounterDirector
extends RefCounted
## Host-authoritative scheduler for the time-gated normal enemy roster.
##
## The director never touches the scene tree. It only answers two questions:
##   * which archetype is allowed to spawn right now (time gate + tier mix)?
##   * how many archetype slots does the spawn budget release right now?
##
## Applying a decision is the job of EnemyRosterSpawner, which owns the arena
## and the actors. Keeping the decision layer free of scene access is what
## makes the same code usable offline (the local world controller applies the
## decisions directly) and networked (the host applies them and replicates the
## result). Clients never schedule anything on their own.
##
## Difficulty and variety follow elapsed match time only. Player level never
## gates the roster.

## Maximum archetype slots released by a single tick. Guards against a burst
## after a long frame stall; the leftover budget stays in the accumulator.
const MAX_DECISIONS_PER_TICK: int = 6

var spawn_config: SpawnDefinition
var rng: RandomNumberGenerator
var run_id: int = 0
var spawn_sequence: int = 0
var elapsed_seconds: float = 0.0

var _roster: Array[EnemyDefinition] = []
var _alive_by_type: Dictionary[StringName, int] = {}
var _alive_total: int = 0
var _budget: float = 0.0

## Collects the roster from the content registry. Only definitions flagged as
## roster entries take part; boss actor definitions reuse the same schema and
## are skipped.
func configure(registry: ContentRegistryService, config: SpawnDefinition, run_identifier: int = 0) -> void:
	spawn_config = config
	run_id = run_identifier
	_roster.clear()
	if registry != null:
		for content_id in registry.content_ids():
			var definition := registry.definition_copy(content_id) as EnemyDefinition
			if definition == null or not definition.roster_entry:
				continue
			_roster.append(definition)
	_roster.sort_custom(func(a: EnemyDefinition, b: EnemyDefinition) -> bool:
		if is_equal_approx(a.min_match_seconds, b.min_match_seconds):
			return String(a.id) < String(b.id)
		return a.min_match_seconds < b.min_match_seconds)
	reset()

## Clears every counter. Called on run start and on run end so a retry never
## inherits the previous run's roster state.
func reset() -> void:
	spawn_sequence = 0
	elapsed_seconds = 0.0
	_budget = 0.0
	_alive_by_type.clear()
	_alive_total = 0

func set_elapsed(seconds: float) -> void:
	elapsed_seconds = maxf(0.0, seconds)

func roster() -> Array[EnemyDefinition]:
	return _roster.duplicate()

func alive_count(type_id: StringName) -> int:
	return int(_alive_by_type.get(type_id, 0))

func alive_total() -> int:
	return _alive_total

func note_spawned(type_id: StringName) -> void:
	_alive_by_type[type_id] = alive_count(type_id) + 1
	_alive_total += 1

func note_removed(type_id: StringName) -> void:
	var current := alive_count(type_id)
	if current <= 1:
		_alive_by_type.erase(type_id)
	else:
		_alive_by_type[type_id] = current - 1
	_alive_total = maxi(0, _alive_total - 1)

## Archetypes whose unlock time has already passed.
func eligible_definitions() -> Array[EnemyDefinition]:
	var result: Array[EnemyDefinition] = []
	for definition in _roster:
		if definition.min_match_seconds <= elapsed_seconds:
			result.append(definition)
	return result

## Index of the current time tier inside SpawnDefinition.time_tier_seconds.
func tier_index() -> int:
	if spawn_config == null or spawn_config.time_tier_seconds.is_empty():
		return 0
	var index := 0
	for tier in range(spawn_config.time_tier_seconds.size()):
		if elapsed_seconds >= spawn_config.time_tier_seconds[tier]:
			index = tier
	return index

## Relative spawn mix of the current tier. Empty when no tier table is authored,
## in which case EnemyDefinition.spawn_weight is used instead.
func tier_weights() -> Dictionary:
	if spawn_config == null or spawn_config.tier_weights.is_empty():
		return {}
	var index := tier_index()
	if index < 0 or index >= spawn_config.tier_weights.size():
		return {}
	return spawn_config.tier_weights[index]

## Global cap on living normal enemies for the current tier.
func population_cap() -> int:
	if spawn_config == null or spawn_config.time_tier_caps.is_empty():
		return 40
	var index := tier_index()
	if index < 0 or index >= spawn_config.time_tier_caps.size():
		return spawn_config.time_tier_caps[0]
	return spawn_config.time_tier_caps[index]

## Normal enemies per second for the current tier.
func spawn_rate() -> float:
	if spawn_config == null:
		return 0.0
	return EnemySpawnDirector.time_spawn_rate(spawn_config, elapsed_seconds)

## Time-based difficulty multiplier. It never touches the player level.
func difficulty_multiplier() -> float:
	if spawn_config == null:
		return 1.0
	return EnemySpawnDirector.time_difficulty_multiplier(spawn_config, elapsed_seconds)

## Weighted pick among the eligible archetypes that still have room left.
## Returns an empty id when nothing may spawn.
func roll_type() -> StringName:
	var candidates: Array[EnemyDefinition] = []
	var weights: Array[float] = []
	var mix := tier_weights()
	for definition in eligible_definitions():
		if alive_count(definition.id) >= definition.max_alive:
			continue
		var weight := float(mix.get(String(definition.id), definition.spawn_weight))
		if not is_finite(weight) or weight <= 0.0:
			continue
		candidates.append(definition)
		weights.append(weight)
	if candidates.is_empty():
		return &""
	var total := 0.0
	for weight in weights:
		total += weight
	if total <= 0.0:
		return &""
	var roll := rng.randf() * total
	for index in candidates.size():
		roll -= weights[index]
		if roll <= 0.0:
			return candidates[index].id
	return candidates[candidates.size() - 1].id

## Advances the spawn budget and returns the archetype slots it releases.
## Every decision carries the run id, a monotonic sequence and the archetype id
## so a host can replicate it and a client can detect duplicates.
func advance(delta: float) -> Array[Dictionary]:
	var decisions: Array[Dictionary] = []
	if spawn_config == null or delta <= 0.0:
		return decisions
	if _alive_total >= population_cap():
		# Shed load instead of banking an unbounded burst.
		_budget = minf(_budget, 1.0)
		return decisions
	_budget = minf(_budget + spawn_rate() * delta, 12.0)
	var released := 0
	while _budget >= 1.0 and released < MAX_DECISIONS_PER_TICK:
		var type_id := roll_type()
		if type_id == &"":
			break
		_budget -= 1.0
		released += 1
		spawn_sequence += 1
		decisions.append({
			"run_id": run_id,
			"spawn_seq": spawn_sequence,
			"enemy_type_id": type_id,
			"server_tick": Engine.get_physics_frames(),
		})
	return decisions
