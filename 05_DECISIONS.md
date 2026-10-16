# 05 — DECISIONS / ASSUMPTIONS / OPEN QUESTIONS
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
