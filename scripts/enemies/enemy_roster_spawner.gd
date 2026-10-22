class_name EnemyRosterSpawner
extends Node
## Applies the encounter director's decisions to the arena.
##
## The spawner owns the parts of a spawn that need the scene tree: the safe
## position, the archetype scene, the stat scaling and the injection of the
## shared services. It never decides *what* spawns - that is the encounter
## director's job - so the same scheduler can drive an offline run and a
## replicated host.

var registry: ContentRegistryService
var spawn_config: SpawnDefinition
var arena: ArenaGeometry
## Container the spawned actors are added to.
var actors: Node2D
var combat: CombatService
var audio: EnemyAudioService
## Layer that hosts the attack telegraphs.
var telegraph_layer: Node2D
## Supplies the living players of the run.
var players_provider: Callable
## Shared navigation of the arena.
var navigation: Callable
var rng: RandomNumberGenerator

var _definitions: Dictionary[StringName, EnemyDefinition] = {}

func definition_for(type_id: StringName) -> EnemyDefinition:
	if _definitions.has(type_id):
		return _definitions[type_id]
	var definition: EnemyDefinition = null
	if registry != null:
		definition = registry.definition_copy(type_id) as EnemyDefinition
	_definitions[type_id] = definition
	return definition

## Safe radius kept from every living player. It is at least the shared
## exclusion radius and at least 1.5x the archetype blast radius.
func safe_radius(definition: EnemyDefinition) -> float:
	var radius: float = spawn_config.exclusion_radius if spawn_config != null else 550.0
	if definition != null and definition.behavior_settings != null:
		radius = maxf(radius, definition.behavior_settings.safe_spawn_radius_px)
	return radius

## Living players of the run.
func players() -> Array[Actor]:
	var result: Array[Actor] = []
	if players_provider.is_valid():
		var provided: Variant = players_provider.call()
		if provided is Array:
			for entry in (provided as Array):
				if entry is Actor:
					result.append(entry as Actor)
	return result

## Spawns one archetype. Returns null when no safe position was found, which
## delays the spawn instead of weakening the safety rules.
func spawn(type_id: StringName, level: int, difficulty: float, existing: Array[Actor]) -> EnemyActor:
	var definition := definition_for(type_id)
	if definition == null or definition.scene_path.strip_edges().is_empty():
		return null
	var point: Variant = sample_position(definition, existing)
	if point == null:
		return null
	var scene: PackedScene = load(definition.scene_path) as PackedScene
	if scene == null:
		return null
	var enemy := scene.instantiate() as EnemyActor
	if enemy == null:
		return null
	enemy.position = point
	enemy.combat = combat
	enemy.arena = arena
	enemy.audio = audio
	enemy.telegraph_layer = telegraph_layer
	enemy.targets_provider = players_provider
	enemy.navigation = navigation
	actors.add_child(enemy)
	apply_scaling(enemy, definition, level, difficulty)
	return enemy

## Samples a position that is outside every living player's safe radius, clear
## of the geometry and reachable.
func sample_position(definition: EnemyDefinition, existing: Array[Actor]) -> Variant:
	if arena == null or spawn_config == null or rng == null:
		return null
	var live := players()
	if live.is_empty():
		return null
	var origin: Vector2 = live[0].global_position
	var avoid: Array[Vector2] = []
	for player in live:
		avoid.append(player.global_position)
	var world_view: Vector2 = get_viewport().get_visible_rect().size / 2.0
	var visible := Rect2(origin - world_view, world_view * 2.0)
	return EnemySpawnDirector.sample_safe(origin, avoid, safe_radius(definition), visible, arena, spawn_config, rng, existing)

## Applies the archetype multipliers and the time based difficulty curve.
## The legacy level scaling stays in place so the early game keeps its feel;
## the time based multiplier only ever scales the new archetypes on top.
func apply_scaling(enemy: EnemyActor, definition: EnemyDefinition, level: int, difficulty: float) -> void:
	var stage: int = floori(maxi(0, level - 1) / 10.0)
	var level_scale: float = 1.0 + 0.28 * stage + 0.025 * maxi(0, level - 1)
	var hp_scale: float = level_scale * definition.hp_multiplier * maxf(1.0, difficulty)
	enemy.stats.max_hp *= hp_scale
	enemy.health.maximum = enemy.stats.max_hp
	enemy.health.current = enemy.stats.max_hp
	enemy.stats.move_speed *= definition.move_speed_multiplier
	enemy.stats.damage_multiplier = (1.0 + 0.15 * stage + 0.015 * maxi(0, level - 1)) * maxf(1.0, difficulty)
