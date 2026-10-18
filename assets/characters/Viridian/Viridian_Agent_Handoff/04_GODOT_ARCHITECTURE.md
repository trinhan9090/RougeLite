# 04 — Godot integration & contracts

## Invariants
- Extend existing shared modules: `CharacterDefinition`, `SkillDefinition`, `SkillRuntime`, `CombatEventBus`, `AugmentManager`, `VisualController`, `AudioRouter`, `TargetingService`, `ProgressionManager`.
- One shared damage application system. One shared projectile executor. No character-name branching in generic modifier code. No direct mutation of definition Resources at runtime.
- Viridian should be addable by data registration, four skill effect configurations and small visual adapters only.

## Suggested paths (adapt to repository)
```
characters/viridian/definition.tres
characters/viridian/viridian_visual.tscn
characters/viridian/skills/emerald_bolt.tres
characters/viridian/skills/plasma_lance.tres
characters/viridian/skills/arcane_prison.tres
characters/viridian/skills/molecular_orbit.tres
characters/viridian/skills/photon_cataclysm.tres
characters/viridian/animations/*.tres
characters/viridian/vfx/*.tscn
characters/viridian/audio/*.tres
characters/viridian/import/source_manifest.json
```

## Data contract (example conceptual JSON, not asserted as existing API)
```json
{
 "character_id":"viridian", "class_id":"mage", "skill_slots": {
  "basic":"emerald_bolt", "J":"plasma_lance", "K":"arcane_prison",
  "L":"molecular_orbit", "I":"photon_cataclysm"
 }, "unlock_levels":{"J":3,"K":6,"L":9,"I":11},
 "visual_profile":"viridian_pixel_v1",
 "source_asset_profile":"mugen_doom_private_poc"
}
```

## Effect implementation
- Emerald Bolt => reusable ProjectileExecutor; spawn projectile event, trail renderer, collision report.
- Plasma Lance => reusable BeamExecutor / LineHitQuery; multi-target hit once/cast; residual field via GroundAreaExecutor.
- Arcane Prison => GroundAreaExecutor + reusable StatusEffect(ROOT), per-target resistance/caps.
- Molecular Orbit => ShieldComponent + OrbitingHitboxComponent, shared with future orbital passive cores.
- Photon Cataclysm => BeamPatternExecutor (fan + stagger) composed of BeamExecutor; global per-target hit cap.

## Capability truth table
| Skill | Projectile split | Echo cast | AOE expand | Pierce | Shield modifier | Orb modifier |
|---|---|---|---|---|---|---|
| Emerald Bolt | yes | possible | no | yes | no | no |
| Plasma Lance | no | yes | beam width only | innate beam pierce | no | no |
| Arcane Prison | no | yes | yes | no | no | no |
| Molecular Orbit | no | guarded/refresh only | orbit radius only | no | yes | yes |
| Photon Cataclysm | no | guarded | beam width/angle if implemented | innate | no | no |

## Stable combat protocol
`CastRequest(character_id, skill_id, target_vector/point, input_mode)` -> authority checks skill unlocked, CC state, cooldown, valid target -> alloc `cast_id` -> `CastStarted` -> pattern/areas created -> `DamageResolved`/`StatusApplied` -> `CastFinished` -> VFX cleanup. Visuals subscribe only and never grant damage. Track entity IDs, skill IDs and `origin_augment_id`; block duplicate proc chains via depth/trigger policy.

## Validation
- Registry loads all resources after import; skill unlock state is deterministic.
- Importer produces validated JSON/PNG/SFX and plays frames with accurate frame durations; does not generate Godot scene edits before source audit passes.
- On reload and map transition, no dangling hitboxes/audio loops.
- Keep all active VFX responsive to runtime modifiers, especially width, radius, count and direction.
