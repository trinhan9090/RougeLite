class_name EnemyBehaviorRegistry
extends RefCounted
## Resolves a behaviour id into a behaviour module.
##
## The lookup is by EnemyDefinition.behavior_id, never by a display name, so
## new archetypes plug in through data only.
##
## The modules are loaded by path on demand instead of being preloaded: the
## content validation only needs the id list, so the editor never has to pull
## the whole behaviour chain into memory while it scans the project.

## Every behaviour id the project knows about.
const BEHAVIOR_IDS: Array[StringName] = [
	&"chase_contact",
	&"chase_slam",
	&"lunge_melee",
	&"kite_shoot",
	&"telegraph_aoe",
	&"proximity_bomb",
]

## Behaviour id to module path.
const BEHAVIOR_PATHS: Dictionary[StringName, String] = {
	&"chase_contact": "res://scripts/enemies/behaviors/chase_contact_behavior.gd",
	&"chase_slam": "res://scripts/enemies/behaviors/chase_slam_behavior.gd",
	&"lunge_melee": "res://scripts/enemies/behaviors/lunge_melee_behavior.gd",
	&"kite_shoot": "res://scripts/enemies/behaviors/kite_shoot_behavior.gd",
	&"telegraph_aoe": "res://scripts/enemies/behaviors/telegraph_aoe_behavior.gd",
	&"proximity_bomb": "res://scripts/enemies/behaviors/proximity_bomb_behavior.gd",
}

static func has_behavior(behavior_id: StringName) -> bool:
	return BEHAVIOR_IDS.has(behavior_id)

static func behavior_ids() -> Array[StringName]:
	return BEHAVIOR_IDS.duplicate()

## Creates a fresh behaviour module. Returns null for an unknown id so the
## caller can fall back to the legacy inline steering instead of guessing.
static func create(behavior_id: StringName) -> EnemyBehavior:
	var path: String = BEHAVIOR_PATHS.get(behavior_id, "")
	if path.is_empty():
		return null
	var script: Script = load(path) as Script
	if script == null:
		return null
	return script.new() as EnemyBehavior
