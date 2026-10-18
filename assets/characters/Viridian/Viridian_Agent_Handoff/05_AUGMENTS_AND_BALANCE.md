# 05 — Upgrade and synergy specification

## Existing pool policy
Shared global stats cores are unbounded; each mechanic passive has max 4–5 ranks per existing game settings. Unlock/rank progression for character active skills is separate from random passive upgrades. Show 1 of 3 valid choices per level. Eligibility uses runtime capability + conflicts + prerequisite + rank cap; revalidate at commit.

## Core compatibility examples
| Core | Basic | J | K | L | I | Comments |
|---|---|---|---|---|---|---|
| Projectile Split | yes | no | no | no | no | only physically instantiated projectile |
| Pierce | yes | innate | no | no | innate | don't apply twice if native infinite pierce |
| Echo Cast | optional | yes | yes | guarded | guarded | anti-proc cap |
| Area Expansion | no | beam width type | yes | orbit radius type | beam width | specific typed modifiers |
| Shield Strength | no | no | no | yes | no | pooled universal shield buff |
| Cooldown Reduction | no/basic interval handled separately | yes | yes | yes | yes | follow global cap |
| Status Duration | no | no | yes | no | no | respect elite/boss CC policy |
| Orb Count | no | no | no | yes | no | orbit component must support count |

## Skill-specific augment synergies — new shared data wiring, not mandatory exclusive cores
- Emerald Bolt + Split + OnHitSpark => multiple real projectiles; triggered explosion policy defaults `ONCE_PER_PRIMARY_TARGET` unless game already defines other policy.
- Plasma Lance + Echo + Beam Width => duplicated beam after a deterministic delay. Prevent Echo-generated cast from re-triggering Echo itself.
- Arcane Prison + AoE Expansion + Damage-vs-CC => larger setup zones and higher damage to rooted targets; avoid increasing root indefinitely.
- Molecular Orbit + Shield Strength + OnShieldBreakShockwave => shared shield-break event, NOT skill-name hardcoding.
- Photon Cataclysm + Cooldown Refund on Kill => cooldown return capped per ultimate cast; channel must remain bounded.

## Evolution and conflicts
- Branch example: `CATACLYSM_FOCUSED_BEAM` (single concentrated beam) **exclusive** with `CATACLYSM_EXTRA_RAYS` (multi-beam direction), per-skill scope. This is an optional signature proposal, not automatically in demo pool.
- Conflict schema fields: `augment_id`, `skill_id`, `requires_capabilities`, `blocks_ids`, `requires_ids`, `max_rank`, `granted_capabilities`, `removed_capabilities`.
- On one selection, recalculate pool; exclude incompatible choices only for that skill instance, not other characters' valid skills.

## Balance risks and clamps
- Cap total per-target multibeam hits per ultimate cast (default 2), regardless of number of beams.
- Cap per-target tick rate in K and L; distinct orbs must not multiply damage unbounded through collider overlap.
- Root immunity/resistance to prevent boss permanent CC; do not secretly nerf visuals.
- Dynamic combat modifiers must not rescale already-resolved damage; snapshots at cast start unless skill explicitly channels and recomputes.
- These numbers are DEMO DEFAULTS and should be changed only in data tuning files after playtest.
