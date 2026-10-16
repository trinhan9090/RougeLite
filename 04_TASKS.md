# 04 — TASKS / MILESTONE EXECUTION PLAN
**Endless Survival Demo · agent-ready backlog · v1.0**

`[ ]` Not started; `[~]` In progress (convert to [ ] or [x] after work); `[x]` Verified complete. A checkbox can be marked done only with linked evidence in `docs/WORK_LOG.md`. All tasks below initially **not started**; no project code is claimed to exist.

## M0 — Foundation / buildable skeleton
- [ ] **M0-01** Create Godot 4 project, main scene, application boot, autoload only for settings/content, placeholder menu; Godot editor/import headless clean. Evidence: startup log and command.
- [ ] **M0-02** Type-safe content definition Resources (character, skill, ranks, augment, effect, map, enemy, boss); stable content IDs and validation. Tests: duplicate IDs, missing ranks, empty reference, out-of-bounds values.
- [ ] **M0-03** Establish deterministic `RunState`, independent RNG streams; seed shown in debug overlay. Test same seed+state gives same sampled sequence and different streams don't interfere.
- [ ] **M0-04** Create test harness and CI/local test script, smoke boot and parse. Evidence: passing baseline tests, and test runner nonzero exit on a deliberate failing test.
- [ ] **M0-05** Implement `InputMap` defaults + key remap persistence + Auto/Manual settings selection. Verify keys after restart.
**Exit gate M0:** skeleton launches without warnings, data resources load, tests can run independently.

## M1 — Movement, combat and EXP vertical slice
- [ ] **M1-01** Player physics controller: WASD and normalized diagonal movement, collision against map bounds/obstacles. Test player speed diagonal equals cardinal.
- [ ] **M1-02** Enemy actor framework: HP, team, AI chase, collision, death signal once, enemy stats from data. Test one enemy dies once.
- [ ] **M1-03** TargetingService nearest eligible enemy within range, deterministic tie-break; invalid enemy ignored. Test none/tie/just outside range.
- [ ] **M1-04** Shared DamageResolver physical/magic/true, shield, crit, death, on-hit, status. Unit test exact damage given seeded RNG and defense.
- [ ] **M1-05** Basic attacks Astra/Vex/Boros via generic attack-controller + melee/projectile strategies; nearest target auto and attack cooldown. Verify 3 basics by manual play.
- [ ] **M1-06** XP orb spawner/pickup and level curve; multi-level XP queue test; HUD HP/EXP/level. No double collect.
- [ ] **M1-07** Three-card pause menu selects one valid offer, resumes safely; no duplicate offerings. Add repeated infinite stat cores and caps. Test level progression > 100 from fixtures.
**Exit gate M1:** player can move, enemies chase, auto attack, gain levels, select 3 cards, die/restart.

## M2 — Generalized skills and capability-driven augments
- [ ] **M2-01** Slot skill runtime, cooldown, rank progression, free unlock at lv3/6/9/11, max 4/4/4/3. Test all thresholds.
- [ ] **M2-02** Auto/Manual skill request using identical cast pipeline and skill-specific targeting; bind J/K/L/I. Test no auto-casts manual.
- [ ] **M2-03** Skill executor protocols for projectile pattern, ground area, instant beam, self shield, dash, status; capability validation. Negative mismatch tests.
- [ ] **M2-04** Event envelope, deterministic modifier order, root id, depth/proc/projectile budgets, dedupe. Test explosive proc loops terminate.
- [ ] **M2-05** EligibilityEvaluator + OfferGenerator with bound skill target; three valid unique choices; capped upgrades removed.
- [ ] **M2-06** Implement generic `ProjectileSplit`, `Multishot`, `Pierce`, `EchoCast`, `AreaExpand`. Show same Split effect works Astra J and Vex L; rejected Boros J.
- [ ] **M2-07** Implement `ExplosionOnHit`, `OnKillBurst`, `CooldownRefund`, `ShieldReflect`, `DashShockwave`, `Execute`, `Homing`. Automated trigger policies and budgets.
- [ ] **M2-08** Run 4-way regression: split + multishot + echo + explosion; assert event depth/projectile/proc limits and no duplicate kills.
**Exit gate M2:** data-only augment binding works across at least 2 characters; incompatible offers filtered; all shared effects tested.

## M3 — Full three-character ability kit
- [ ] **M3-01** Astra ranks J/K/L/I + visual placeholders + status/magic tests.
- [ ] **M3-02** Vex ranks J/K/L/I + burst/roll/pierce tests, projectile budget.
- [ ] **M3-03** Boros ranks J/K/L/I + area, shield reflect, dash and transform tests.
- [ ] **M3-04** Selection UI displays three characters, class role, base stats, skill preview; selected character creates correct skills and input bindings.
- [ ] **M3-05** Skill tooltip and status indicators, disabled locked slots, upgrade card targeting explicit; compatibility tests across all 3.
**Exit gate M3:** one 1–11 run each character, all actives unlocked, manual/auto functional, skill ranks and caps accurate.

## M4 — Boss, maps, escalating endless loop
- [ ] **M4-01** Map templates (temple, forest, volcanic) with random seed layout/obstacles; reachability verifier + safe fallback.
- [ ] **M4-02** Enemy SpawnDirector with radius constraint and adaptive caps; spawn candidate attempts capped, defer when unsafe.
- [ ] **M4-03** BossGate milestone 10/20/...; states and bank XP; assert exactly one boss per milestone, no false transition.
- [ ] **M4-04** Boss Stone Warden telegraphs, phases, attack hitboxes; manual dodge playtest.
- [ ] **M4-05** Boss Ember Sentinel (or fully tested second boss archetype), telegraphed laser and summons; tuning.
- [ ] **M4-06** Transition manager preserves upgrades and HP proportion, handles temp effects, clears old world safely; deterministic next-map pool.
- [ ] **M4-07** Endless fallback boss variants, stage scaling, >Lv30 progression; tests forced level jumps and banked XP crossing thresholds.
**Exit gate M4:** each character defeats first boss, changes map and continues leveling; 3 map variants, 2 bosses, survives beyond Lv30 in automated accelerated simulation.

## M5 — UX, stability, release demo
- [ ] **M5-01** Main menu/start/retry/pause/keybind UI; clean resolution scaling, readable fonts, fullscreen/windowed.
- [ ] **M5-02** SFX/VFX placeholders, boss warnings, damage feedback, orb magnet pickup, run summary.
- [ ] **M5-03** Profiling, object pooling where needed, memory leak and event subscription cleanup; target 100 enemies/300 projectiles frame time measurement.
- [ ] **M5-04** Comprehensive regression suite and 3-character manual QA script; critical bugs addressed.
- [ ] **M5-05** Packaging Windows demo + launch/readme + source license/asset attribution + optional debug toggles.
- [ ] **M5-06** Attempt Web export as **secondary validation only** if Godot exporter and gameplay support it. Web export limitations documented, not a prerequisite to Windows demo.
**Exit gate M5:** launchable Windows demo and reproducible Godot source, recorded QA and known limitations.

## Cross-cutting test checklist
| Test ID | Setup | Expected |
|---|---|---|
| A-01 | Astra J + split | exact scheduled extra projectiles according to rank |
| A-02 | Vex L + split | same implementation is used, no character switch logic |
| A-03 | Boros J + split | no offer and validator rejects binding |
| A-04 | Split rank 5 selected again | cannot offer rank 6 |
| A-05 | Skills unlocked 3/6/9/11 | free initial rank and normal 3-choice upgrade |
| A-06 | Lv10 achieved twice via XP batching | exactly one active boss |
| A-07 | XP earned during boss | banked, then drained into sequential offers |
| A-08 | Map obstacles block sampled enemy spawn | spawn reroll/defer, never overlap |
| A-09 | No target in attack range | no basic attack/cooldown consumption |
| A-10 | Mode changed to manual | no automatic active casting; basic remains auto |
| A-11 | Keybinds remapped and restart | new bindings preserved |
| A-12 | Split+multishot+echo+explosion | finite events and projectiles, no freeze |
| A-13 | All complex cores capped at high level | exactly 3 distinct stat options remain available |
| A-14 | Player dies during boss lethal frame | game over once, no accidental next map |
| A-15 | 100 enemies/300 projectiles test arena | no critical hangs; logged frame time |

## Implementer task report template
```text
Task ID:
Intent / scope:
Files created/modified:
Architectural interfaces changed? Yes/No (ADR link if yes)
Tests executed (exact command):
Test output / evidence path:
Manual validation performed:
Known limitations / follow-up:
Task state: [ ] / [x]
```

## Demo manual acceptance tour (must execute)
1. Select each class and move 8 directions; basic auto-target nearest in range.
2. Switch to Manual, use J/K/L/I after unlock, remap J to U and verify cast.
3. Force XP to lvl3/6/9/11 and check free unlock, 3 distinct upgrades, maximum ranks.
4. Equip split on Astra J and Vex L; look for projectile geometry and expected damage.
5. Force boss lvl10; check warnings, exactly one spawn, banked EXP, victory-to-map handoff.
6. Verify new map layout different, no spawn-kill in 2s transition immunity, all augments remain.
7. Force lvl30/40 and check ongoing boss/map rotation plus valid augment offers.
8. Kill player; see run summary, restart resets run-only state but preserves bindings.

## Autonomous art handoff (2026-10-16)
Canonical milestone definitions: assets/vfx/Endless_Survival_Art_Agent_Handoff_v1/docs/07_TASKS_AND_ACCEPTANCE.md. Detailed evidence/owner review status: docs/ART_TASKS.md, ART_ACCEPTANCE.md, ART_ISSUES.md and WORK_LOG.md.
- [x] A0 Inventory/snapshot and unchanged supplied originals.
- [x] A1 Reproducible generation/import/schema/PNG/QC pipeline.
- [x] A2 Original four-direction prototype actors and shared visual scene.
- [x] A3 Astra five actual-action VFX.
- [x] A4 Vex five actual-action VFX.
- [x] A5 Boros five actual-action VFX.
- [x] A6 Three tile themes and100 seeds/theme validation.
- [x] A7 Real-executor preview and gameplay/transition integration.
- [ ] A8 Stable60FPS performance gate (Windows demo, stress evidence and provenance delivered; p9523.555ms at100/300 does not meet stable60FPS).
Visual approval remains PENDING; checkboxes denote tested prototype implementation, not owner art acceptance.
