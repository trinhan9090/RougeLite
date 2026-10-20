# 05 — DECISIONS / ASSUMPTIONS / OPEN QUESTIONS
2026-10-17 latest user approval: add Atyu as fourth hero, adapt actual supplied MUGEN attacks to existing controls/J/K/L/I, side-facing left/right accepted, varied combo imagery without fighting-game controls. CHARACTER becomes twenty small avatar slots, four available and sixteen question marks; click reveals details then select. See ADR-2026-006. Private local testing scope and unresolved artwork rights retained; no redistribution approval inferred.
**Decision register and ADR index · v1.0 · 2026-10-15**

## How to use
`LOCKED` is an explicit user-approved requirement. `PROPOSED` is assistant recommendation agreed only implicitly as development direction. `DEMO DEFAULT` is a provisional value selected to make demo executable. `OPEN` requires future user decision if it would materially change architecture/gameplay. Do **not** claim a DEMO DEFAULT was approved by the user. Change any LOCKED choice only with new user instruction and a dated entry.

## Locked decisions — from user conversation
| ID | Decision | Status | Consequence |
|---|---|---|---|
| D-001 | 2D top-down endless survival with level-up, EXP orbs and continuous bosses | LOCKED | XP/offer/boss are primary loop |
| D-002 | Three class types Mage / ADC / Brute; playable demo has 3 characters | LOCKED | character data model is class-independent |
| D-003 | WASD movement | LOCKED | normalized axis input |
| D-004 | Active skill keys J(1), K(2), L(3), I(4), remappable | LOCKED | InputMap settings persistent |
| D-005 | Auto/Manual selectable by player | LOCKED | cast intent source changed; cast implementation same |
| D-006 | Basic attack automatically targets nearest valid enemy | LOCKED | no manual attack key required |
| D-007 | Free unlock skill 1/2/3/ultimate at levels 3/6/9/11 | LOCKED (unlock milestones); free unlock was accepted during design direction | deterministic slot unlocks |
| D-008 | Skill rank caps 4,4,4,3 | LOCKED | max rank validation |
| D-009 | Every player level gives choice 1 from 3 cores | LOCKED | offer generator must guarantee three |
| D-010 | Infinite stat-core stack; mechanism passive cap 4 or 5 levels | LOCKED | default 5, individually configurable to 4 |
| D-011 | Universal core applies across suitable abilities/characters; not duplicated per character | LOCKED | capability/executor architecture |
| D-012 | Boss spawn driven by player level (not elapsed time) | LOCKED | BossGate at milestones |
| D-013 | Every 10 levels, map changes to a random map in pool with randomized obstacles | LOCKED (milestone intent) | transition after boss kill chosen as accepted design direction |
| D-014 | Enemies spawn sufficiently far from player to avoid spawn-kill | LOCKED | safe radius and reachable-space checks |
| D-015 | Avoid using Lux name/character for prototype; similar but original adjusted skill kit | LOCKED | own characters/assets |
| D-016 | Develop PC-first with Godot 4/GDScript; Web later | PROPOSED / accepted by user | implementation targets Windows |
| D-017 | Multiple passive cores can coexist; no global passive slot limit explicitly chosen | DEMO DEFAULT | use per-core rank cap only |

## Architecture rules accepted as direction
| ID | Rule | Status |
|---|---|---|
| A-001 | Composition + data-driven Skills/Augments Resources | PROPOSED / accepted direction |
| A-002 | Capability predicates must be backed by actual runtime executors | PROPOSED / accepted direction |
| A-003 | Generic projectile split across all compatible directional projectile skills | LOCKED intent |
| A-004 | Modifier/event engine bounded: no unbounded recursive passive chains | engineering invariant |
| A-005 | One DamageResolver for all actors | engineering invariant |
| A-006 | User experience shows skill-targeted offer rather than hidden automatic assignment | DEMO DEFAULT |

## Demo-default values (fully editable in data/config)
| ID | Value | Status | Rationale / needs validation |
|---|---|---|---|
| P-001 | Astra 130HP, Vex150HP, Boros260HP; all base stats in gameplay spec | DEMO DEFAULT | distinguish class identities |
| P-002 | Skills' ranks/cooldowns/damage listed in gameplay spec | DEMO DEFAULT | unblock agent content |
| P-003 | Mechanic augments up to 5 ranks, signature up to 1 | DEMO DEFAULT | parameterizable caps |
| P-004 | Boss every 10 levels, map after boss defeat | first portion LOCKED; transition detail DEMO DEFAULT | avoid midfight teleport |
| P-005 | First arena pool: Ruined Temple, Enchanted Forest, Volcanic Arena | DEMO DEFAULT | meaningful layout contrasts |
| P-006 | Basic XP 6/8/10/15; XP formula `25 + 12(L-1) + 1.8(L-1)^1.45` | DEMO DEFAULT | untested pacing |
| P-007 | Map spawn safe radius 550px, 30 attempts, 2s transition invulnerability | DEMO DEFAULT | measurable anti-spawnkill |
| P-008 | Projectile budget 64/root, secondary proc budget 32, depth 3 | DEMO DEFAULT | anti-runaway |
| P-009 | 100 enemies/300 projectiles/60fps midrange PC | DEMO TARGET | hardware dependent |
| P-010 | Stop world on upgrade modal | DEMO DEFAULT | prevents unfair damage |
| P-011 | Boss arena HP restore 15% max after victory; reset cooldowns and temporary statuses | DEMO DEFAULT | between-stage relief |
| P-012 | Manual directional aim uses mouse | DEMO DEFAULT | PC ergonomics |
| P-013 | 1 reroll each 10 levels, max 3 stored | DEMO DEFAULT | optional UI convenience |
| P-014 | Damage and defense formulas, caps and stage scaling in gameplay spec | DEMO DEFAULT | balance later |
| P-015 | Boss I Stone Warden, Boss II Ember Sentinel original design | DEMO DEFAULT | 2 boss archetypes |
| P-016 | Auto use of self-buffs when enemy within threat radius | DEMO DEFAULT | prevents pointless cooldown when safe |
| P-017 | Three unique options may be differing bound skills with same core ID; otherwise unique core card IDs | DEMO DEFAULT | explicit skill targeting |

## Open decisions (Agent must isolate; do not silently decide if architecture-changing)
| ID | Topic | Fallback for demo | Escalation point |
|---|---|---|---|
| Q-001 | Final visual style: pixel art, vector, hand-drawn | placeholder shapes | before polished asset production |
| Q-002 | Manual targeting UX with controller / touchscreen | PC mouse only | prior to port |
| Q-003 | Advanced targeting preferences: nearest vs lowest HP vs boss priority | nearest only | before target selection options |
| Q-004 | Future monetization, online co-op/LAN | none, offline only | before multiplayer architecture |
| Q-005 | Whether skills beyond first 4 may evolve into branching evolutions | only rank and augments | before post-demo progression |
| Q-006 | Number of different core passives a run may own (cap or no cap) | no cap | before long-term balance |
| Q-007 | Web build full parity and supported browsers | best effort later | after Windows demo |
| Q-008 | Boss minions and boss CC rules for all levels | boss stagger policy in gameplay spec | during balance pass |

## ADR template
Create `docs/adr/ADR-YYYY-NNN-short-title.md`:
```markdown
# ADR: <decision title>
Date:
Status: Proposed / Approved / Superseded
Context:
Options considered:
Decision:
Consequences/tradeoffs:
Affected contracts:
Tests required:
User approval/reference:
```

## Change log
- 2026-10-15 — Created implementation-ready docs set from agreed conversation; filled unapproved numerical details as DEMO DEFAULT, no source code claimed. Later user approvals must be added with dates and supersession trail.

## Implementation records (no LOCKED requirement changes)
- 2026-10-15: User selected missing Split rank-5 value: **6 extra shots at 65% damage**. Ranks 1-4 unchanged; gameplay table and mechanic Resource updated.
- 2026-10-15: User selected Shield Reflect boss cap: **1% boss maximum HP per hit**, also bounded by reflected absorbed damage. Stored in combat_limits.tres.
- 2026-10-15: [M2 implementation mapping](adr/ADR-2026-002-m2-universal-runtime.md) records common executors, bound ranks/offers, modifier snapshots and shared budgets. No LOCKED requirement/settings schema change. Baseline kit data remains incomplete M3 content; boss boundary remains M4.
- 2026-10-15: M0 uses Godot 4.7.2 stable / GDScript / Compatibility renderer, from an existing local archive. Complete verification and environment recorded in WORK_LOG.md. No gameplay default rebalanced.
- Input handoff files copied into canonical docs/; originals retained at root as historical snapshots. Root AGENTS.md mirrors 03_AGENTS.md. Current task progress lives only in docs/04_TASKS.md.
- Registry definitions are private deep snapshots, detached copies exposed to readers; exported graph edges use Array[Resource] with concrete type validation to avoid a Godot self-typed Resource script leak. Ownership/capability contracts unchanged.
- Preview uses seed 20261015 and Auto as initial settings defaults; both are preview/settings controls, not LOCKED gameplay additions. Settings schema v1 stores only physical key bindings/mode/version in user://settings.cfg; per-run state remains separate.
- 2026-10-15: User requested GitHub publication and selected a new PRIVATE `RougeLite` repository. Publication is blocked (no usable authentication; Git metadata writes denied). No remote creation/commit/push claimed.
- 2026-10-15: M1 adds basic-only CombatLoadoutDefinition projections, actual projectile/melee basic executors and 8 global stat effects. Full CharacterDefinitions/actives/mechanic capability adapters remain M2/M3; accepted architecture and LOCKED rules unchanged. Spawn/progression configs are registered typed content rather than unvalidated constants.
- 2026-10-15: M1 preview explicitly stops at the pending first boss milestone after its level-up choice. Full boss/map progression remains M4; this is a preview scope boundary, not a change to the locked boss schedule. M1-05 manual play remains pending; automated evidence is recorded in WORK_LOG.md.
- 2026-10-15: User explicitly accepted M1 ("duyet M1"), closing the pending M1 milestone acceptance gate; no claim of assistant-performed native manual play. Continue M2 in canonical backlog order. LOCKED gameplay/architecture unchanged.

2026-10-15 implementation records:
- User authorizes autonomous M3-M5 completion and asks to record unresolved questions rather than wait while travelling. This changes the clarification workflow, not any LOCKED rule.
- Full native rank behavior uses immutable SkillBehaviorDefinition graphs and per-run RankEffectSystem state. [Implementation ADR](adr/ADR-2026-003-full-demo.md). No character-ID branches in shared combat/augment code.
- Three seeded connected map templates, a level-based BossGate, two telegraphed boss archetypes, auxiliary summons, banked EXP and post-victory transitions are implemented. Volcanic lava deals5 true damage per0.5s active tick with a warning interval; spawn points and the starting area exclude lava. Normal enemies ignore environmental lava in this demo (provisional balance policy).
- Adaptive population cap:40 at level1,+2 per level, hard cap110. Projectile/proc/depth budgets remain64/32/3 and world projectile cap300. Full-load measurement overrides only its detached fixture cap. See BALANCE_LOG.md; stable60FPS is not claimed.
- Reflection cannot crit/reapply outgoing-stat or mark multipliers; the confirmed augment cap remains1% boss max HP/hit. Echo/Split scaling includes native HP scaling and delayed damage fields.
- Windows private packaging uses an exported PCK and exact official portable runtime with extracted license notices. Source rights remain reserved. Web export was attempted but matching templates are absent. Art/tuning/localization/license questions remain in OPEN_QUESTIONS.md.

- 2026-10-16: Explicit user correction supersedes P-012 mouse aim: Manual skills use last nonzero movement/current facing; cursor position ignored for player casts. WASD keeps facing when stopped. Basic nearest-target auto attack remains unchanged. User also requests Vietnamese UI; enabled Vietnamese locale without settings-schema change.

- 2026-10-17: Explicit user correction authorizes caster hand/torso projectile and beam origin, and Astra L nearest eligible enemy in range with maximum-range facing fallback when none exists, in both modes. This supersedes directional-only L placement. Other Manual skills remain facing based. ADR: docs/adr/ADR-2026-004-cast-origin-target-assist.md.

- 2026-10-17: Latest explicit user instruction authorizes torso hurtboxes separate from locomotion and continuing V3-A6 Vex / V3-A7 Boros before Astra visual approval. Faces may remain blank; preserve hats, hair, coats and readable action states. Skill identities/ranks and other locked gameplay remain unchanged. ADR-2026-005. Human visual approval remains pending.

- 2026-10-17: User explicitly selected Boros sword carry "Chúc xuống cạnh hông"; apply to idle/run, preserve distinct combat actions. Latest correction requests Astra/Boros buff/shield center alignment; presentation-only shared body-center metadata, no gameplay changes.

- 2026-10-17: User explicitly requests no further QA screenshot/contact-sheet/video exports; required gameplay sprite/VFX assets remain part of implementation. Complete changes in the current playable project, retain necessary automated verification, and record implementation/tests/known limitations in docs. User performs direct visual play-testing. This overrides prior media-export deliverables for subsequent work. Existing prior evidence is preserved.

- 2026-10-17: User approved the proposed Atyu P1-P2 source decoder and standalone Godot animation browser. This is a private source-inspection experiment, not approval to add Atyu gameplay, replace the three current heroes, alter boss CC, or distribute mod assets. No QA image/video exports; preserve source metadata and label unresolved/duplicate entries.

- 2026-10-17: Latest explicit user instruction supersedes movement-based Manual direction: ground-plane indicator and directional Manual casts use last accepted attack direction, independent of WASD and mouse. Default RIGHT until first attack. Basic remains automatic nearest. Astra L nearest-target assistance retained; empty Manual fallback uses attack direction, Auto fallback movement facing. Fullscreen default and fractional/expand stretch authorized. See ADR-2026-007.

Latest display clarification: actual render viewport1920x1080 and native-scale UI, not640x360 fitted to monitor. Supersedes prior pixel viewport defaults; art textures and combat numbers unchanged.

2026-10-17: User explicitly requests Training with full health, no skill cooldown, stationary immortal boss. Authorizes separate local sandbox with unlocked skills. Normal PLAY/progression unaffected. See ADR-2026-008.

2026-10-17 latest user extension: numeric HP/EXP instead of percent, Space for basic attack, floating damage above hit enemies. Space is additive to existing normal auto basic, uses same nearest valid target and interval. Training basic-auto checkbox supports isolated Space tests. Existing settings v1 accepts optional basic_attack binding; no resource content mutation.

2026-10-17: User explicitly authorizes supplied Atyu SND extraction, CNS mapping, Basic/J/K/L/I AudioStreamPlayer2D integration and animation/VFX synchronization for local testing. Presentation-only addition; missing source sound references are documented with explicit in-package substitutions. No distribution permission inferred. See ATYU_AUDIO.md.

2026-10-17: User explicitly requests removing Atyu voice sounds from all basic attacks, retaining sword sounds. Remove S5,36/S5,35 from basic/combo cue lists only; active skill and impact audio unchanged.

2026-10-17 explicit user correction: Viridian body animation must use actual supplied MVC2_DrDoom-AI(Maro) SFF/AIR, not an original generated fallback. Runtime now uses source side-view body artwork with mirrored left/right; vertical motion retains last horizontal facing. Does not change combat/input contracts. Visual approval pending.

2026-10-17 explicit user approval: add Graveshade Tactical Suppressor as sixthhero ADC using supplied actual Punisher MUGEN source. Preserve all current hero mechanics, shared CombatSystem/UniversalAugment, inputs/AutoManual/progression. Keep20avatarboxes with6available/14unknown. No media exports; user direct playtests. Source numerical rank parameters are DEMO DEFAULT per handoff, not newlyLOCKED. Same-session steering: reduce Doom/Viridian Basic visual bolt and hit flash slightly; damage/hitbox remain unchanged.

2026-10-18 explicit user correction: Doom/Viridian ultimate immobilizes its caster throughout the supplied hell_answers_to_me_for_i_am_doom (1) voice intro and ray release. Rays start after the intro finishes. Supersedes previous half-speed channel and0.65s-only ultimate startup. Damage/ranks/fan and shared Augment contracts unchanged.

2026-10-18 latest user steering supersedes the preceding wait-for-voice requirement: start dialogue on cast, release rays after original short0.65s windup without waiting for dialogue, let voice finish naturally. Immobilize only through windup/ray completion, then restore movement while dialogue continues.

2026-10-18 user explicitly authorizes seventh hero named Tofu using assets/characters/Tofu/Toji Fushiguro and supplied handoff. Tofu supersedes Toji working name. Preserve first six hero gameplay, current last-attack Manual aim and native1080p. Bruiser melee role is represented by existing brute class (no class-schema expansion). Private local art/audio provenance retained; source audio bank meanings require listening per handoff.

2026-10-18 latest explicit user targeting correction: remotely placed ground damage zones target nearest reachable living enemy in skill range in both Auto and Manual, including Training boss. Supersedes density priority for Viridian K/Tofu K/Graveshade K. Reuses Astra L existing nearest-with-facing-fallback policy. Static placement snapshots remain static; no-enemy fallback uses max-range attack direction (Manual) or facing (Auto). Self auras, near-caster mines, dash/melee and directional beams/projectiles unchanged.
