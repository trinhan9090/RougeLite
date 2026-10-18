# 02 — Viridian character/gameplay specification

## Locked decisions
- Name **Viridian** (working), class **Mage**, specialization **Control Mage**; magical energy color emerald green; auto basic targets closest valid enemy in attack radius.
- J Plasma Lance, K Arcane Prison, L Molecular Orbit, I Photon Cataclysm. Unlock at character level **3, 6, 9, 11**. J/K/L each 4 ranks total, I 3 ranks total. Unlock is free alongside ordinary 1-of-3 core selection (as previously proposed; follow repository precedence if different).
- Skill activation supports Auto and Manual; default hotkeys J/K/L/I; remappable. Auto target resolution server/gameplay-side, rendering independent.

## Character role and failure modes
- Mid-range zone control with delayed, high-value damage; strong against grouped melee mobs, weaker when skill cooldowns overlap and surrounded by mobile elites.
- Not a summoner; none of his skills generates a persistent pet or melee body. Plasma visuals must not accidentally look like Astra's blue/white celestial light.
- Base silhouette: armored techno-sorcerer, mask/hood, high collar and gauntlets; keep visually original rather than copying Doom's exact costume/insignia.

## Demo defaults — all units expressed in Godot 2D pixels and seconds
| Stat | Value | Notes |
|---|---:|---|
| Max HP | 95 | lower than Brute |
| Base attack damage | 17 | damage engine applies global modifiers |
| Attack interval | 0.70 s | auto only on target in range |
| Attack range | 310 px | line of sight required where applicable |
| Move speed | 215 px/s | tuning default |
| Crit chance | 5% | shared cap rules |
| Base damage multiplier | 1.0 | no custom damage engine |
| Projectile speed (basic) | 590 px/s | max distance 340 px |

## Basic — Emerald Bolt
- Closest living target in max range; rotate toward target point at cast start; one narrow luminous **green projectile** with a brighter near-white core and short trail. Valid on-hit explosion small but NOT AOE damage by default.
- Attack interval 0.70 s, 17 base damage, hit radius 7 px, hit once per target per cast. Projectile inherits basic-tag modifiers and crit. Candidate SFF/VFX: Photon Shot state 1510/1511.
- Capability set: `PROJECTILE`, `DIRECTIONAL`, `SPLITTABLE`, `PIERCEABLE`, `HOMING_COMPATIBLE`, `ON_HIT`, `CRITTABLE`. Requires actual projectile executor.

## J — Plasma Lance | unlock level 3
- Fast straight **beam/line hit** from gauntlet, penetrates enemies, telegraph 0.16 s and live damage window 0.18 s, total visual finish within 0.50 s. Default range 420 px, line width 24 px, cooldown 5.5 s, base damage 48; one damage application per enemy per cast.
- Rank 2: width 32 px. Rank 3: +30% damage to boss (only J). Rank 4: lingering plasma trail for 1.4 s dealing 7 damage per 0.5 s per enemy subject to dedupe/cap rules.
- `BEAM`, `DIRECTIONAL`, `LINE_AOE`, `PIERCING_BEAM`, `ECHOABLE`, `WIDTH_EXPANDABLE`; **NOT** projectile split, unless a future beam fork module is explicitly implemented.
- Source candidate: Plasma Beam states 1450,1460,1470; fallback Unibeam. Adapt horizontal original assets into Godot beam VFX with orientation and line hitbox controlled by gameplay.

## K — Arcane Prison | unlock level 6
- Place green electric rune cage centered near largest cluster of enemies within 330 px of character; manual mode points at cursor/directional aim, clamps to range. Radius 86 px, delay 0.24 s, cooldown 12 s; applies `ROOT` 1.6 s to normal mobs, 0.7 s to elite and 0.3 s to boss by default. Light damage 15 on initial pulse; **root** prevents walking, not skills/casts by default.
- Rank 2: radius 110 px; rank 3: +0.4 s normal root / +0.15 s elite root / +0.05 s boss root subject to CC caps; rank 4: exit explosion 45 damage when field ends, once per target.
- `AREA`, `GROUND_TARGETED`, `CROWD_CONTROL`, `ROOT`, `DAMAGE`, `ECHOABLE`, `AREA_EXPANDABLE`; **not** `SPLITTABLE`.
- Source candidate: Electric Cage state family 3000–3019; source needs actual FX verification.

## L — Molecular Orbit | unlock level 9
- Instant defensive cast creates barrier absorbing 55 damage for 7 s plus 2 orbiting energy orbs at radius 52 px. Orb contact causes 12 damage with per orb/target internal cooldown 0.7 s; cooldown 18 s begins at cast. Orb follow owner and do not seek off-screen targets.
- Rank 2: 3 orbs; rank 3: orbit angular velocity +30%; rank 4: 4 orbs and +25 shield points. Refresh behavior: reactivation replaces remaining shield/orbs; not stack infinite shields.
- `SHIELD`, `ORBITAL_DAMAGE`, `BUFF`, `DURATION_SCALABLE`, `SHIELD_SCALABLE`, `ORBIT_COUNT_MODIFIABLE`; **not** projectile split by default.
- Source candidate Molecular Shield 1480–1500 / 3120–3121. Confirm exact frame sources; use procedural orbital paths and unique IDs.

## I — Photon Cataclysm | unlock level 11
- Massive multibeam channel with 0.65 s windup, 5 rays fired over 0.75 s in ±35° fan around locked targeting direction. Each ray 460 px by 18 px, base 68 damage, per target **global ultimate hit cap**: no more than 2 ray hits during one ultimate (balancing safeguard). Cooldown 32 s; character movement 50% during windup/channel.
- Rank 2: 7 rays and angle spread unchanged; rank 3: 9 rays and final impact burst (radius 85, 55 damage, only once per target); hit cap unchanged.
- `MULTI_BEAM`, `CHANNEL`, `LINE_AOE`, `DAMAGE`, `ECHOABLE`, `BEAM_WIDTH_COMPATIBLE`; **not** generic projectile split.
- Source candidate Photon Array 3080–3099; verify beam timings/frames before using.

## Targeting and timeline
- Manual: aim with mouse when available; if no valid mouse target then last nonzero aim vector; controls remappable. Auto: choose closest enemy (K can choose densest reachable cluster) with valid line of sight; never randomly retarget midway through a cast unless the skill explicitly specifies homing.
- Skill unlock/ranks must be data-driven and shown in UI. No original Marvel input command or super bar.
- Each cast has stable cast_id and event provenance; effects VFX-only on client, damage from CombatSystem; hitbox collision layers are independent of animation sprites.

## Explicit edge cases
- Auto casts while target leaves range: cancel before commitment, otherwise cast at locked direction.
- K target death does not cancel prison ground field. Boss still able to act if only rooted; prevent perma-CC via resistance policy.
- L orb collision cooldown tracked per orb+target; removal cleans all timers/particles; shield damage does not recursively trigger on-hit attack procs.
- I multibeam ray overlap uses global per-target cap; interrupt cleans up active beams and hitboxes.
- Moving between maps cancels temporary VFX/fields but retains permanent upgrades; document how L shield persistence behaves (demo default: clear shield during transition).
