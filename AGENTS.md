# AGENTS.md — Endless Survival: Time-Gated Enemy Roster Expansion

> **Scope:** Implement five **new non-boss enemy archetypes** with distinct visual identity, animations, VFX and SFX, plus a host-authoritative time-based encounter roster for the existing Godot 4/GDScript Endless Survival game. This file is an implementation handoff for a coding AI Agent, **not proof the feature has been installed or tested**.
>
> **Authority:** Latest user requirements supersede older examples. Preserve established architecture (Enemy/Combat/Status/Audio/VFX/Network/Content registries, Universal Augment System). Do **not** replace existing systems with parallel character-specific implementations. Inspect actual project code first; names below are suggested interfaces, not assumed existing paths.

## 0. Locked decisions — do not reinterpret

1. **Keep the basic enemy** as an early-game unit; introduce **five additional enemy archetypes**, not all at match start.
2. **Difficulty and enemy variety scale with elapsed match time**, independent of the EXP/level of any player. Each new enemy has its own minimum unlock time, spawn weight, and concurrent caps. Unlocks are cumulative (once unlocked, remain eligible).
3. **Multiplayer: 1–4 players, host-authoritative combat/spawn/timer**. Clients never independently schedule enemies, damage, explosions, or AoE. Solo uses the same encounter rules when appropriate, with an authoritative local world controller.
4. **Boss appears at 180, 360, 540… seconds**, even if older bosses are alive. The five new units are **normal enemies**, do not advance or block the boss timer, and are not a substitute for bosses.
5. One **randomized map per match**, no map transition in demo. Enemy spawn points must respect validated map topology, player safety distance and obstacle collision.
6. **EXP and levels are personal**; augment selection does not pause the match and does not provide invulnerability. The F-key revive channel disables basic attacks and active/automatic skill casts by the reviver; enemies may still target and damage them.
7. UI and combat gameplay remain functional with existing characters and enemy roster. Do not break basic enemy behavior.
8. **No exported screenshots, videos or contact sheets required.** Run headless/automated tests where available and in-game smoke tests when accessible; report textual logs/results only. Never claim to have executed tests unless executed.
9. VFX/SFX **must be visually and audibly distinguishable from the basic enemy**. Do not merely recolor the standard attack and call the result complete. No external copyrighted sound/sprite asset may be assumed licensed; prefer original, generated-in-project or license-verified audio/graphics.

## 1. Required enemy archetypes

All values in the table and following specs are **DEMO DEFAULTS** to tune using actual game scale, movement speed and TTK. Speeds are *relative to the existing baseline enemy*, not hard-coded pixels/second. Damage values are scaled from `basic_enemy_damage` for comparability; avoid mutating shared Resources.

| Stable ID | Display name | Archetype | First eligible at | HP x basic | Speed x basic | Base attack | Readability / identity |
|---|---|---|---|---:|---:|---|---|
| `enemy_bulwark` | Iron Bulwark | Slow, high-HP melee | **02:00** | 4.0 | 0.50 | Heavy contact smash, wind-up | Oversized armored silhouette, orange cracks and dust impact |
| `enemy_skitter` | Razor Skitter | Fast, low-HP melee | **04:00** | 0.55 | 1.80 | Fast close strike, short recovery | Small angular silhouette, cyan streaks, fast feet |
| `enemy_marksman` | Hollow Marksman | Ranged projectile | **06:00** | 1.10 | 0.85 | Aimed straight projectile | Distinct long-barrel shape, violet projectile tracer |
| `enemy_ritualist` | Cinder Ritualist | Ranged AoE caster | **09:00** | 1.45 | 0.70 | Ground-targeted AoE with warning | Tall caster silhouette, amber/red glyph telegraph |
| `enemy_bomber` | Volatile Husk | Melee proximity explosion | **12:00** | 0.85 | 1.15 | Primed proximity blast; no repeated detonation | Glowing unstable core, lime-yellow pulsing warning |

**Design intent:** Maintain escalating threat diversity; Bulwark soaks shots, Skitter pressures positioning, Marksman forces dodging, Ritualist denies territory, Bomber punishes tight groups. The roster is not five cosmetic variations of the standard melee enemy.

## 2. Behavior + audiovisual contracts per enemy

### E1 — Iron Bulwark (`enemy_bulwark`) — slow melee tank
- **Combat:** Follow reachable nearest valid living player using shared pathing; soft aggro retarget every 0.5–1.0s. Within range, **0.55s anticipation**, slam cone or short frontal disk **once**, 1.7s recovery/cooldown; melee damage **1.8× baseline**. Low mobility compensated by HP; does not permanently body-block passages.
- **Animation:** idle heavy breathing, slow two-step walk, shoulders back during wind-up, committed overhead slam, hit-stagger, death collapse.
- **VFX signature:** ember-orange cracks in armor; strong ground dust ring and **short-lived fractured-earth decal** when slam lands; telegraph footprint 0.55s before damage; separate from default hit VFX. Visual hit radius must match collider.
- **SFX signature:** low-pitched armor clank on steps, rising rocky scrape for wind-up, one dry bass impact + pebble rattle on contact, heavy armor collapse on death. Spatial attenuation; avoid excessive bass stacking with multiple Bulwarks.
- **Counterplay:** Step out of marked range during wind-up. No surprise instant high-damage hit.

### E2 — Razor Skitter (`enemy_skitter`) — fast, fragile melee
- **Combat:** Path toward nearest valid living player; use short **0.22s lunge** after entering pre-attack range (max displacement clamped and collision checked), then strike once, 1.2s cooldown. HP low; damage **0.70× baseline**. No infinite dash loops, no tunneling through solid map geometry.
- **Animation:** 6–8-frame rapid run, crouch-before-leap, blur-fast strike, quick recovery, ragdoll-like defeat if style permits.
- **VFX signature:** thin cyan/teal **speed streaks** along dash trajectory, 1–2 quick afterimages (pooled), crescent-shaped claw slash and small spark-on-hit. **Afterimages purely visual**: never spawn extra hitboxes.
- **SFX signature:** high-pitched scratchy footfalls, short stereo/positional whoosh, sharp claw tick/hit, dry squeal on death. Audio polyphony cap for crowd spawns.
- **Counterplay:** Low HP makes it easy to kill, but it can overwhelm a distracted player.

### E3 — Hollow Marksman (`enemy_marksman`) — ranged single-target
- **Combat:** Prefer standoff radius; if target too close, retreat or sidestep using bounded pathfinding, never teleport. Every **2.2s**, aim **0.4s** at a chosen target, then spawn one authoritative projectile with speed **~1.5× reference standard enemy move speed** (tune to actual scale), wall collision, one hit maximum unless existing piercing definition says otherwise; damage **0.9× baseline**. Constrain max engagement distance and line of sight; if blocked, reposition instead of shooting through obstacles.
- **Animation:** visible aim pose, muzzle discharge, recoil, reload loop, fall/death.
- **VFX signature:** **violet thin aiming line or narrow reticle** during telegraph; purple-magenta bullet core with readable trail and small violet burst; projectile visually separated from player shots; consistent damage collider.
- **SFX signature:** two-stage metallic aim click / compact arcane rifle crack; zipping projectile; crisp light hit spark and cartridge-like clatter (fictionalized). Distinct from default melee hit.
- **Counterplay:** Player can see aim direction, use obstacles, dodge shot.

### E4 — Cinder Ritualist (`enemy_ritualist`) — ranged telegraphed AoE
- **Combat:** Maintain distance, keep LOS where needed; select a **ground position snapshot near a valid player** (do not home telegraph after lock), place circle telegraph at target position for **1.25s**, apply AoE damage **1.25× baseline** at expiration; optionally a tiny ~0.6s visual smolder with **no additional damage** at first (avoid undocumented DoT). Cooldown **5.0s**. AoE hits each eligible player **once per cast_id**; apply faction filters; cannot place center inside impassable map cells. Radius config derived from real game geometry.
- **Animation:** raising staff, channeling, release pulse, brief fatigue and retreat.
- **VFX signature:** **red/amber inscribed rune circle** that fills clockwise, central pillar of sparks/flame at detonation, brief scorch decal fade; clear ring boundary and charge cue. Audio+color+shape distinct from both Marksman and player green Mage skill.
- **SFX signature:** reverse airy inhale and faint rune chimes when circle appears, escalating crackle, one punchy flame burst on impact, short ember fizz out. Volume scales by distance, not number of impacted players.
- **Counterplay:** Time to leave outlined area before detonation; no invisible instant AoE.

### E5 — Volatile Husk (`enemy_bomber`) — melee exploding when close
- **Combat:** Chase reachable living player. When target enters **trigger radius**, enter `PRIMING`, show distinct visual/audio countdown for **0.8s**, then **explode once** in a radius, inflict **1.6× baseline** damage per living player in range, despawn through normal death lifecycle **without repeating explosion**. During priming, movement reduced/stopped (choose stopped for first demo); player can escape. If killed before charge completes, **cancel blast by default**; no on-death explosion unless added as a future variant. Must not spawn within trigger radius of a player; grace period after spawn for fairness. Explosion can affect multiple players, **never allies or other enemies** unless explicit friendly-fire design changes.
- **Animation:** unstable idle core pulsing, accelerating body tremor during prime, rapid squash/stretch + detonation disappearance.
- **VFX signature:** **lime-yellow pulsating core**, expanding dashed danger ring of exact AoE radius, rising hazard sparks, brief saturated yellow-green radial shockwave + dissolving fragments. Explosion must be readable even with green player spell effects (distinct silhouette/ring and warm yellow emphasis).
- **SFX signature:** periodic low electrical beep that accelerates during prime, bright rising whine, heavy compressed pop + fragment crackle, non-looping tail; when killed early, add extinguish hiss rather than blast sound.
- **Counterplay:** Recognize beeping ring, move out or kill before prime finishes. Does not explode immediately on first frame of proximity.

## 3. Encounter pacing and time-gated spawn rules

### 3.1 Difficulty tiers (time measured from host-authoritative `match_elapsed_seconds`)

| Match time | Available enemies | Suggested mix of eligible enemy spawn *weights* | Global normal enemy cap (demo) |
|---|---|---|---:|
| 00:00–01:59 | Basic only | Basic 100 | 45 |
| 02:00–03:59 | + Bulwark | Basic 85 / Bulwark 15 | 55 |
| 04:00–05:59 | + Skitter | Basic 70 / Bulwark 12 / Skitter 18 | 70 |
| 06:00–08:59 | + Marksman | Basic 60 / Bulwark 12 / Skitter 18 / Marksman 10 | 85 |
| 09:00–11:59 | + Ritualist | Basic 48 / Bulwark 13 / Skitter 19 / Marksman 12 / Ritualist 8 | 95 |
| 12:00+ | + Bomber | Basic 38 / Bulwark 14 / Skitter 20 / Marksman 13 / Ritualist 8 / Bomber 7 | 110 |

All weights relative, normalized when rolling (they are **not** guaranteed quotas). Prefer smooth interpolation of spawn-rate/difficulty **within** tiers to avoid sharp discontinuities, while maintaining exact unlock gates. Suggested normal-unit cap counts only normal enemies; boss slots tracked independently. Performance caps are DEMO DEFAULTS, adapt to measured desktop/mobile/network budget; if max reached, skip or defer normal spawns, **never silently skip a required 180-second boss event**.

### 3.2 Spawn-rate / per-type caps
- Initial target global base spawn rate: **~0.7 enemies/second**, increasing moderately with elapsed time up to **~2.2 enemies/second** by minute 12, subject to cap. Do **not** spawn all simultaneously on tier change; use a spawn budget/accumulator with deterministic seeded RNG.
- **Concurrent per-type cap** (demo): Bulwark 6, Skitter 25, Marksman 12, Ritualist 6, Bomber 10. Calculate as `min(type_cap, global_remaining)` and optionally scale by team size/config. Excess rolls can retry a bounded number of alternative eligible types, then skip safely.
- Difficulty scaling can adjust enemy stats gradually after 12:00 but must not erase roles: Bulwark always slower and sturdier; Skitter always faster and frailer than baseline. Recommended starter formula `difficulty_multiplier = 1 + 0.06 * floor(elapsed_seconds/180)` with sensible cap based on profiling. **Never use player level as the gate.**
- `RUNNING` match state only; no spawning in menu, lobby, generating map, or after GAME_OVER. Match time must start at actual synchronized START event and **not reset when a boss dies**.
- At exact 180s thresholds, boss scheduler runs independently; normal spawn scheduler remains active. No gameplay pause during augment selection/revive. All host-generated spawn events uniquely tagged with `run_id`, monotonic `spawn_seq`, `enemy_type_id`, position, server tick and deterministic visual seed where needed.

### 3.3 Safe spawn and navigation rules
- Spawn outside all living players' **minimum safe radius** (scale from map cell size; start at ≥ 1.5× Bomber blast radius). No overlap with colliders, bosses, revive targets, obstacles or an unsafe dead end.
- Prefer existing off-camera/edge-of-engagement spawn system; if it can put a bomber inside attack radius, override candidate validation.
- Validate walkable connected component and accessible route to at least one living player. Retry finite number of candidates, then delay spawn — never weaken safety checks to meet quota.
- Team of 3–4: enemies may pursue different targets; choose target on host based on distance, reachability and stable tie-break `peer_id`, update with hysteresis to avoid rapid retargeting. When no living target remains, stop spawning/game over as per existing rules.

## 4. Integration contracts (data-driven)

Use existing project systems wherever present; avoid hard-coding special behavior based on enemy display name inside shared Combat/Spawn/Network systems.

**Suggested data contract (adapt to actual Resource architecture):**

```gdscript
# Suggested fields for EnemyDefinition Resource; integrate with existing type(s).
@export var enemy_type_id: StringName
@export var min_match_seconds: float = 0.0
@export var spawn_weight: float = 1.0
@export var max_alive: int = 10
@export var hp_multiplier: float = 1.0
@export var move_speed_multiplier: float = 1.0
@export var attack_behavior_id: StringName
@export var visual_profile_id: StringName
@export var audio_profile_id: StringName
```

- **Composition**: `ChaseAndSlam`, `LungeMelee`, `KiteAndShoot`, `TelegraphGroundAoE`, `ProximityPrimeAndExplode` can be reusable attack/AI behavior modules configured by Resources. Ordinary shared damage calculation, hit immunity, faction filters, target validation, status effects, event bus, pooling and death/EXP awarding are reused.
- **Combat events**: Every damage-bearing effect gets `source_entity_id`, `attack_instance_id`, `server_tick`, target set or target ID, faction, and an idempotence key. No multiple damage to same target from one AoE/one explosion unless explicit damage ticks exist. On-death/on-hit procs must obey depth and per-tick event budgets.
- **Visual layer**: AnimationPlayer/AnimatedSprite2D and VFX are **presentations of committed gameplay state**, not sources of combat truth. `telegraph_started` and `attack_resolved` events are host-driven; client plays local animations/SFX and receives authoritative hit/HP events. Animation timing should align with host state durations; latency should never erase warning window visually without reconciliation.
- **Audio layer**: `AudioStreamPlayer2D`, spatial mix groups (`EnemyFootstep`, `EnemyAttack`, `EnemyWarning`, `EnemyImpact`), pool voices, distance attenuation, short cooldown of repeated SFX, priority for dangerous telegraphs. Audio asset references may be absent; fallback to original procedural wavs or documented placeholders, but never silent completion.
- **Networking**: Host owns AI, spawn rolls, projectile physics, AoE positions, timers, damage, deaths and EXP drops. Clients interpolate movement; replicate only important attack telegraph/start/resolve and IDs. SFX/VFX on client are locally rendered and should not be networked frame-by-frame. Late join/reconnect receives authoritative roster, remaining attack timers and active telegraphs so threat state is not lost.
- **Death/XP**: Reuse existing per-player EXP pickup eligibility, kill credit and loot behavior. Exploder's self-removal on successful explosion should not accidentally award duplicate kill EXP. Existing revive lockout of attacking remains unchanged.
- **Performance**: object pooling for bullets/telegraph visuals/dust/trails, update AI targeting at throttled intervals, avoid all-enemies/all-players O(N²) checks per frame, group threat audio to stop 15 identical beeps sounding simultaneously. Include simple graphics budget mode for Android without changing damage radius or warning duration.

## 5. Visual art direction and assets

- Style: game's existing **Wizard-of-Legend-inspired pixel readability**, nearest-neighbor filtering, consistent sprite pivot at feet and top-down 3/4 orientation. Keep game palette and pixel density consistent, but **five recognizable silhouettes and telegraphs** even in grayscale/low-effects mode.
- Produce gameplay-ready animation sets for **idle, walk, wind-up/aim/prime, attack, hit, death** for each enemy. Missing directional sprites should be handled through tested orientation/fallback, not mirror northern sprites in a way that creates obvious backward movement.
- Keep on-screen particle count bounded. Gameplay-critical telegraphs must stay clearly visible regardless of VFX settings. Align visual impact frames to authoritative damage event, and implement quick fading when attacks are interrupted.
- User does **not** request screenshots/videos or contact sheets. You may use internal debug views to validate visuals, but do not export them as deliverables.
- Only use original or properly licensed asset material and record filename, origin, licence, attribution in existing asset manifest. Do not lift M.U.G.E.N/anime assets from unrelated character packs for these enemies by default.

## 6. Required tests and acceptance criteria

### 6.1 Time gating and pacing
- `EN_TIME_01`: At 00:00–01:59 only basic enemy spawns; five new types absent.
- `EN_TIME_02`: Bulwark first eligible **at** 02:00, not before.
- `EN_TIME_03`: Skitter first eligible 04:00, Marksman 06:00, Ritualist 09:00, Bomber 12:00, none early.
- `EN_TIME_04`: Cumulative unlock: basic and older types still eligible after later gates; weighted distribution verified with deterministic seed (test eligibility directly, do not assert exact random counts).
- `EN_TIME_05`: 03:00/06:00/etc. boss still spawns when normal enemy cap full and older boss alive.
- `EN_TIME_06`: No enemy scheduling while in lobby/menu/game-over; run reset resets encounter counters once only.
- `EN_TIME_07`: Spawn candidates honor collision/navmesh/safe radius; bomber never spawns already primed or on top of player.
- `EN_TIME_08`: Each type cap and global cap enforced without infinite loops or RPC flood.

### 6.2 Mechanics and combat correctness
- `EN_AI_01`: Bulwark is visibly slower than baseline, survives more hits, and slam only resolves after telegraph.
- `EN_AI_02`: Skitter is faster, lower HP, lunge respects walls and has one damage application.
- `EN_AI_03`: Marksman aims and fires one authoritative projectile; walls block; retreat works; misses do not cause damage.
- `EN_AI_04`: Ritualist ground target locks at cast, telegraph radius matches hitbox, each eligible target takes at most one hit.
- `EN_AI_05`: Bomber prime is cancellable by pre-explosion death, explosion applies once to valid players only and enemy does not respawn from own death event.
- `EN_AI_06`: All five can be killed by each player's basic/skills/augments and use existing EXP drops correctly.
- `EN_AI_07`: Repeated `attack_resolved` RPC or event does not duplicate hit, EXP or explosion.
- `EN_AI_08`: Reviver holding F cannot attack/cast, remains valid enemy target, and enemy damage may interrupt revive as existing rules define.

### 6.3 Visual, audio, multiplayer and performance
- `EN_VFX_01`: Each enemy has distinct idle/movement/attack/death visuals, correct pivots and readable hazard colors/shapes; no shared standard-enemy attack flash as the **sole** VFX.
- `EN_SFX_01`: Each enemy has different attack/warning/hit cues and audible feedback; SFX pool caps polyphony, no endless sound after despawn.
- `EN_NET_01`: Host + 3 clients receive same spawn IDs/type/position and damage outcome; clients cannot force-spawn unit or forge attack hits.
- `EN_NET_02`: Late join/reconnect gets active enemies, boss state and attack telegraphs; no duplicated instance IDs.
- `EN_NET_03`: Enemy roster and ability events survive latency tests at 30/80/150ms RTT and 0/1/3% simulated loss; important events reliable with sequencing as needed.
- `EN_PERF_01`: Profile 4-player host at late-game cap (including bosses): record host frame time, AI time, simultaneous enemy/projectile counts, bandwidth, sound voices; tune **normal enemy** caps without touching 180s boss schedule.
- `EN_REG_01`: Original basic enemy, boss timer, map, personal EXP/level, auto/manual skills, augment selection and revival still work.

**Definition of Done:** Five types registered, data/behaviors/VFX/SFX implemented, time-based roster runs under the match state, test commands executed where environment permits, no critical regressions, user can run Godot and see differentiable enemies. **Text-only report** with passed/failed/not-run cases, commands, changed files and blockers. If Godot binary/project inaccessible, mark tests NOT RUN and never claim full completion.

## 7. Agent execution plan (do not stop at planning)

1. **Audit** repo (real scripts/scenes/Resources, match clock, existing spawn/AI state, boss timer, networking ownership, VFX/audio conventions). Snapshot current behavior and run baseline checks.
2. **Define reusable behaviors** and data fields, five stable IDs, unlock schedule, unique audio/VFX profiles, resource validation and registration. Do not change boss schedule.
3. **Implement vertical slice E1** (Bulwark) end-to-end: spawn gating, AI, damage, telegraph, animation, sound, sync; run relevant tests.
4. Add **E2** Skitter, **E3** Marksman, **E4** Ritualist, **E5** Bomber one at a time with targeted tests after each.
5. Integrate weighted **EncounterDirector** with per-type and global caps, safe map spawn, seeded randomness, team targeting, configurable difficulty and independent boss schedule.
6. Validate **solo and LAN multiplayer** with 2 then 4 instances where possible; fault/disconnect tests. Profile late-game performance without silently changing gameplay.
7. Deliver only text results; ensure new content is selectable in spawn debug commands and normal progression; leave QA notes and documented DEMO DEFAULT balance for playtesting.

## 8. Non-negotiable implementation guardrails

- **Do not** start countdown before `RUNNING`; **do not** accidentally spawn boss #2 at 03:00 due to off-by-one sequence mistakes—inspect actual boss scheduler and preserve its defined numbering.
- Do not couple unlock gating to each player's XP/level or to elapsed time in the client's local wall clock.
- Do not put player-only skill augments into enemy behavior code or clone the Combat System; share damage interfaces and maintain faction targeting.
- Do not create generic untelegraphed unavoidable hits; telegraph/collider/range must match, including under packet loss.
- Do not let late-game enemy volume exceed practical host CPU/memory/audio bandwidth; normal spawn budget is allowed to shed load, while scheduled bosses are preserved.
- Do not request confirmation for routine implementation details; record reasonable assumptions as DEMO DEFAULTS. Ask only before changing locked architecture or game mechanics not covered here.
- No images/videos as deliverables, no claims of testing without evidence, and no unrelated code refactors.

## 9. Final report format

Provide: `Implemented`; `Actual assets/VFX/SFX created and provenance`; `Unlock timeline`; `Code files changed`; `Godot test commands/results`; `2- and 4-player networking result`; `Late-game metrics`; `Known issues and balancing knobs`. Clearly label NOT TESTED where applicable. This AGENTS.md does not grant access to the user's local `D:\SelfProject\RougeLite` directory; implementation must happen in the project environment where an agent has filesystem access.
