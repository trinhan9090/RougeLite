class_name EnemyDefinition
extends ContentDefinition
## Authored data for one enemy archetype.
##
## The roster fields drive the time-gated encounter director: an archetype is
## only eligible once the host-authoritative match clock passes
## min_match_seconds, and it competes for spawn slots with spawn_weight while
## alive, bounded by max_alive.

@export var stats: ActorStatDefinition
## Base damage of the archetype before damage_multiplier is applied. The
## archetype's authored attack carries this value and the runtime scales it
## with damage_multiplier, so every archetype stays comparable to the basic
## enemy.
@export var damage: float = 8.0
@export var xp_reward: int = 6
@export var attack_interval: float = 1.0

@export_group("Roster")
## True when this definition is a member of the time-gated normal enemy
## roster. Boss actor definitions reuse this schema but are never part of the
## roster, so they keep the flag off.
@export var roster_entry: bool = false
## Earliest match second at which this archetype may spawn.
@export var min_match_seconds: float = 0.0
## Relative weight among eligible archetypes (weights are normalised at roll time).
@export var spawn_weight: float = 1.0
## Concurrent cap for this archetype.
@export var max_alive: int = 10

@export_group("Scaling")
## Multipliers relative to the basic enemy. Roles must survive scaling:
## Bulwark stays slower and sturdier, Skitter stays faster and frailer.
@export var hp_multiplier: float = 1.0
@export var move_speed_multiplier: float = 1.0
## Damage ratio relative to the basic enemy. The runtime applies it to the
## archetype's authored attack.
@export var damage_multiplier: float = 1.0

@export_group("Behaviour")
## Behaviour module id. Resolved by EnemyBehaviorRegistry; never by display name.
@export var behavior_id: StringName = &"chase_contact"
## Scene instantiated when the archetype spawns. The path is stored instead of
## a packed scene reference so the registry can deep-duplicate the definition.
@export var scene_path: String = ""
@export var behavior_settings: EnemyBehaviorSettings
## Skill used for this archetype's attacks. ContentDefinition, so it joins the
## registry dependency graph.
@export var attack_skill: SkillDefinition
@export var visual_profile: EnemyVisualProfile
@export var audio_profile: EnemyAudioProfile

func references() -> Array[Resource]:
	var result: Array[Resource] = super.references()
	if attack_skill != null:
		result.append(attack_skill)
	return result

func validate() -> PackedStringArray:
	var errors := super.validate()
	if stats == null:
		errors.append("%s: stats reference required" % id)
	else:
		errors.append_array(stats.validate())
	if not is_finite(damage) or damage < 0.0 or xp_reward < 0 or not is_finite(attack_interval) or attack_interval <= 0.0:
		errors.append("%s: invalid enemy damage/reward/interval" % id)
	if not is_finite(min_match_seconds) or min_match_seconds < 0.0:
		errors.append("%s: min_match_seconds must be finite and non-negative" % id)
	if not is_finite(spawn_weight) or spawn_weight <= 0.0:
		errors.append("%s: spawn_weight must be finite and positive" % id)
	if max_alive < 1:
		errors.append("%s: max_alive must be at least 1" % id)
	for field: StringName in [&"hp_multiplier", &"move_speed_multiplier", &"damage_multiplier"]:
		var value: float = get(field)
		if not is_finite(value) or value <= 0.0:
			errors.append("%s: %s must be finite and positive" % [id, field])
	if behavior_id == &"":
		errors.append("%s: behavior_id is required" % id)
	if not EnemyBehaviorRegistry.has_behavior(behavior_id):
		errors.append("%s: unknown behavior_id '%s'" % [id, behavior_id])
	if roster_entry and scene_path.strip_edges().is_empty():
		errors.append("%s: scene_path is required for a roster entry" % id)
	elif not scene_path.strip_edges().is_empty() and not ResourceLoader.exists(scene_path):
		errors.append("%s: missing scene '%s'" % [id, scene_path])
	# Boss actor definitions reuse this schema but are not roster members, so
	# the archetype resources are only mandatory for roster entries. The legacy
	# basic enemy keeps its skill supplied by the run root.
	var archetype := roster_entry
	if behavior_settings == null:
		if archetype:
			errors.append("%s: behavior_settings reference required" % id)
	else:
		errors.append_array(behavior_settings.validate())
	if visual_profile == null:
		if archetype:
			errors.append("%s: visual_profile reference required" % id)
	else:
		errors.append_array(visual_profile.validate())
	if audio_profile == null:
		if archetype:
			errors.append("%s: audio_profile reference required" % id)
	else:
		errors.append_array(audio_profile.validate())
	if attack_skill == null and behavior_id != &"chase_contact":
		errors.append("%s: attack_skill reference required for behaviour '%s'" % [id, behavior_id])
	if attack_skill != null:
		errors.append_array(attack_skill.validate())
	return errors
