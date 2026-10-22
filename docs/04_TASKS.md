# 04 — TASKS / MILESTONE EXECUTION PLAN
**Endless Survival Demo · agent-ready backlog · v1.0**

`[ ]` Not started; `[~]` In progress (convert to [ ] or [x] after work); `[x]` Verified complete. A checkbox can be marked done only with linked evidence in `docs/WORK_LOG.md`. The initial handoff had no implemented tasks. Current checked tasks link to executed evidence below; M3-M5 engineering delivery is recorded below; owner review and disclosed limitations remain.

## M0 — Foundation / buildable skeleton
- [x] **M0-01** Create Godot 4 project, main scene, application boot, autoload only for settings/content, placeholder menu; Godot editor/import headless clean. Evidence: startup log and command.
- [x] **M0-02** Type-safe content definition Resources (character, skill, ranks, augment, effect, map, enemy, boss); stable content IDs and validation. Tests: duplicate IDs, missing ranks, empty reference, out-of-bounds values.
- [x] **M0-03** Establish deterministic `RunState`, independent RNG streams; seed shown in debug overlay. Test same seed+state gives same sampled sequence and different streams don't interfere.
- [x] **M0-04** Create test harness and CI/local test script, smoke boot and parse. Evidence: passing baseline tests, and test runner nonzero exit on a deliberate failing test.
- [x] **M0-05** Implement `InputMap` defaults + key remap persistence + Auto/Manual settings selection. Verify keys after restart.
**Exit gate M0:** skeleton launches without warnings, data resources load, tests can run independently. **VERIFIED 2026-10-15**: [M0 acceptance and per-task evidence](WORK_LOG.md#final-m0-acceptance--2026-10-15).

## M1 — Movement, combat and EXP vertical slice
- [x] **M1-01** Player physics controller: WASD and normalized diagonal movement, collision against map bounds/obstacles. Test player speed diagonal equals cardinal.
- [x] **M1-02** Enemy actor framework: HP, team, AI chase, collision, death signal once, enemy stats from data. Test one enemy dies once.
- [x] **M1-03** TargetingService nearest eligible enemy within range, deterministic tie-break; invalid enemy ignored. Test none/tie/just outside range.
- [x] **M1-04** Shared DamageResolver physical/magic/true, shield, crit, death, on-hit, status. Unit test exact damage given seeded RNG and defense.
- [x] **M1-05** Basic attacks Astra/Vex/Boros via generic attack-controller + melee/projectile strategies; nearest target auto and attack cooldown. Verify 3 basics by manual play. **18 automated checks passed; M1 accepted by user on 2026-10-15. Native manual play was not independently verified by the assistant.**
- [x] **M1-06** XP orb spawner/pickup and level curve; multi-level XP queue test; HUD HP/EXP/level. No double collect.
- [x] **M1-07** Three-card pause menu selects one valid offer, resumes safely; no duplicate offerings. Add repeated infinite stat cores and caps. Test level progression > 100 from fixtures.
**Exit gate M1:** player can move, enemies chase, auto attack, gain levels, select 3 cards, die/restart. **ACCEPTED by user on 2026-10-15 ("duyet M1"); automated implementation evidence retained.** [Acceptance record](WORK_LOG.md#m1-user-acceptance--2026-10-15). [M1 implementation and evidence](WORK_LOG.md#final-m1-implementation-verification--2026-10-15).

## M2 — Generalized skills and capability-driven augments
- [x] **M2-01** Slot skill runtime, cooldown, rank progression, free unlock at lv3/6/9/11, max 4/4/4/3. Test all thresholds. [44 lifecycle checks + 13-suite regression](WORK_LOG.md#m2-01---skill-lifecycle-foundation).
- [x] **M2-02** Auto/Manual skill request using identical cast pipeline and skill-specific targeting; bind J/K/L/I. Test no auto-casts manual. [14 cast checks + real scene tests](WORK_LOG.md#final-m2-verification).
- [x] **M2-03** Skill executor protocols for projectile pattern, ground area, instant beam, self shield, dash, status; capability validation. Negative mismatch tests. [Executor and geometry evidence](WORK_LOG.md#final-m2-verification).
- [x] **M2-04** Event envelope, deterministic modifier order, root id, depth/proc/projectile budgets, dedupe. Test explosive proc loops terminate. [16 envelope checks + combination tests](WORK_LOG.md#final-m2-verification).
- [x] **M2-05** EligibilityEvaluator + OfferGenerator with bound skill target; three valid unique choices; capped upgrades removed. [15 offer checks / 600 seeded offers](WORK_LOG.md#final-m2-verification).
- [x] **M2-06** Implement generic `ProjectileSplit`, `Multishot`, `Pierce`, `EchoCast`, `AreaExpand`. Show same Split effect works Astra J and Vex L; rejected Boros J. [Shared effect evidence](WORK_LOG.md#final-m2-verification).
- [x] **M2-07** Implement `ExplosionOnHit`, `OnKillBurst`, `CooldownRefund`, `ShieldReflect`, `DashShockwave`, `Execute`, `Homing`. Automated trigger policies and budgets. [Two-compatible / one-incompatible matrix](WORK_LOG.md#final-m2-verification).
- [x] **M2-08** Run 4-way regression: split + multishot + echo + explosion; assert event depth/projectile/proc limits and no duplicate kills. [141 combination checks](WORK_LOG.md#final-m2-verification).
**Exit gate M2:** data-only augment binding works across at least 2 characters; incompatible offers filtered; all shared effects tested. **VERIFIED 2026-10-15:** [20 suites / 616 checks, graphical scene/editor checks and limitations](WORK_LOG.md#final-m2-verification). Full character kits remain M3; native manual play is not claimed.

## M3 — Full three-character ability kit
- [x] **M3-01** Astra ranks J/K/L/I + visual placeholders + status/magic tests. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M3-02** Vex ranks J/K/L/I + burst/roll/pierce tests, projectile budget. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M3-03** Boros ranks J/K/L/I + area, shield reflect, dash and transform tests. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M3-04** Selection UI displays three characters, class role, base stats, skill preview; selected character creates correct skills and input bindings. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M3-05** Skill tooltip and status indicators, disabled locked slots, upgrade card targeting explicit; compatibility tests across all 3. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
**Exit gate M3:** one 1–11 run each character, all actives unlocked, manual/auto functional, skill ranks and caps accurate. **ENGINEERING VERIFIED 2026-10-15:** full kits and accelerated three-character progression; human acceptance not claimed.

## M4 — Boss, maps, escalating endless loop
- [x] **M4-01** Map templates (temple, forest, volcanic) with random seed layout/obstacles; reachability verifier + safe fallback. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M4-02** Enemy SpawnDirector with radius constraint and adaptive caps; spawn candidate attempts capped, defer when unsafe. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M4-03** BossGate milestone 10/20/...; states and bank XP; assert exactly one boss per milestone, no false transition. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M4-04** Boss Stone Warden telegraphs, phases, attack hitboxes; manual dodge playtest. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M4-05** Boss Ember Sentinel (or fully tested second boss archetype), telegraphed laser and summons; tuning. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M4-06** Transition manager preserves upgrades and HP proportion, handles temp effects, clears old world safely; deterministic next-map pool. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M4-07** Endless fallback boss variants, stage scaling, >Lv30 progression; tests forced level jumps and banked XP crossing thresholds. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
**Exit gate M4:** each character defeats first boss, changes map and continues leveling; 3 map variants, 2 bosses, survives beyond Lv30 in automated accelerated simulation. **ENGINEERING VERIFIED 2026-10-15:** real boss deaths/transitions to41 and renderer-driven WASD dodge tests; not a human playtest claim.

## M5 — UX, stability, release demo
- [x] **M5-01** Main menu/start/retry/pause/keybind UI; clean resolution scaling, readable fonts, fullscreen/windowed. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M5-02** SFX/VFX placeholders, boss warnings, damage feedback, orb magnet pickup, run summary. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M5-03** Profiling, object pooling where needed, memory leak and event subscription cleanup; target 100 enemies/300 projectiles frame time measurement. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M5-04** Comprehensive regression suite and 3-character manual QA script; critical bugs addressed. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M5-05** Packaging Windows demo + launch/readme + source license/asset attribution + optional debug toggles. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
- [x] **M5-06** Attempt Web export as **secondary validation only** if Godot exporter and gameplay support it. Web export limitations documented, not a prerequisite to Windows demo. [Executed evidence / limitations](WORK_LOG.md#final-m3-m5-demo-verification).
**Exit gate M5:** launchable Windows demo and reproducible Godot source, recorded QA and known limitations. **DELIVERED 2026-10-15:** Windows/source ZIPs,887 regression checks, package/extracted smoke and recorded limitations. Stable60FPS stress target and human acceptance remain unclaimed.

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














## Reported demo bugs
- [x] **BUG-01** Enemy chase stalls at invisible navigation corners: reproduce in real physics, fix cell indexing/steering and verify regression + Windows package. No LOCKED design changes.


- [x] **UI-01** Main menu PLAY / CHARACTER / SETTING, character preview/selection and consolidated settings; verify navigation, selected-character launch and rendered layout.


- [x] **AIM-01** Fix unwanted ranged-basic steering and add Manual facing arrow with matching directional casts; verify moving targets, manual input and Homing regression.


- [x] **ART-01** Integrate user-supplied Vex atlas as data-configured sprite animations in menu/game; verify frame validity, state transitions and package.


- [x] **ART-02** Integrate supplied Boros directional strips and normalize all three character visuals to72px baseline height; keep collision/gameplay unchanged and verify animations, size and package.


- [x] **UI-02** Movement-facing Manual aim, clipped Boros atlas frames, Vietnamese menu/HUD/upgrade presentation; verify opposite-cursor input, moving sprite renderer and localization.


- [x] **ART-03** Remove disconnected neighbouring-pose fragments baked inside Boros source cells; preserve originals, regenerate derived strips and verify all frames plus renderer/package.


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

## Astra current-play VFX revision (2026-10-17)
- [x] ASTRA-VFX-02 Technical delivery: five celestial VFX integrated in current PLAY/Art Preview;35 focused checks,34 current-project suites,6 Python tests and packaged3-profile/3-boss smoke pass. Visual approval remains owner play-test pending. Evidence: reports/astra_vfx02/QUALITY_REPORT.md and test_results.json.



## Original pixel v3 Astra review
Canonical definitions: assets/Endless_Survival_Wizard_of_Legend_Visual_Spec_v3/06_TASKS_QA_ACCEPTANCE.md.
- [x] V3-A0 Snapshot/inventory/source baseline. TECH_PASSED; evidence reports/visual_qa/v3_astra. Human approval PENDING.
- [x] V3-A1 Original pixel tooling, manifest, native board. TECH_PASSED; evidence reports/visual_qa/v3_astra. Human approval PENDING.
- [x] V3-A2 Astra nine states / four directions / fixed feet. TECH_PASSED; evidence reports/visual_qa/v3_astra. Human approval PENDING.
- [x] V3-A3 Actual Basic/J/K/L/I frame VFX lifecycle. TECH_PASSED; evidence reports/visual_qa/v3_astra. Human approval PENDING.
- [x] V3-A4 Courtyard presentation;100 seeds per biome;30-enemy QA. TECH_PASSED; evidence reports/visual_qa/v3_astra. Human approval PENDING.
- [x] V3-A5 Actual Split/Echo/AreaExpand compatibility and comparison. TECH_PASSED; evidence reports/visual_qa/v3_astra. Human approval PENDING.
- [x] V3-A6 Vex original four-direction/nine-state pixel art and actual Basic/J/K/L/I VFX. Latest user explicitly authorizes proceeding; TECH_PASSED, owner visual approval PENDING. Evidence reports/visual_qa/v3_three_heroes/REPORT.md.
- [x] V3-A7 Boros original four-direction/nine-state pixel art and actual Basic/J/K/L/I VFX. TECH_PASSED, owner visual approval PENDING. Evidence reports/visual_qa/v3_three_heroes/REPORT.md.
- [ ] V3-A8 Remaining arenas and boss art; pending Astra visual review (07_AGENT_RUNBOOK step6).
- [ ] V3-A9 Final access settings / performance acceptance; pending Astra visual review (07_AGENT_RUNBOOK step6).
- [ ] V3-A10 Final visually approved release; pending Astra visual review (07_AGENT_RUNBOOK step6).

- [x] V3-FIX-01 User corrections: north legs, actor-centered cast origin, nearest-enemy Astra L with facing fallback. Tests: native frames, real projectile/beam geometry and Auto/Manual targeting.
- [x] V3-FIX-02 Enemy torso hurtbox independent of locomotion collider;11 real-physics checks,38 canonical suites and61 focused live/packed checks pass. Evidence reports/visual_qa/v3_three_heroes/REPORT.md.
- [x] V3-FIX-03 Vex/Boros rear movement; user-confirmed downward sword carry beside hip; roll/haste cleanup; shared Astra/Boros body-centered shield/Titan/guard-hit feedback. TECH_PASSED:39 canonical suites,95 focused live/packed checks,151 pose and2382 frame checks. Evidence reports/visual_qa/v3_fix03/REPORT.md. Direct owner visual play-test pending; no further media exports.

- [x] UI-AIM-03 Native1920x1080 fullscreen render (latest clarification), responsive1:1 menu/HUD; ground-plane Manual arrow and casts from last accepted attack.52 headless /54 live GUI checks pass;41 regression suites verified after targeted rerun of superseded viewport assertion. Evidence: UI_AIM03.md / WORK_LOG.md / ui_aim03_results.json.

- [x] TRAIN-01 Separate training menu mode: full HP, zero active cooldown, stationary immortal real boss, rank/hero/reset controls, numeric HP/XP, Space basic, floating enemy damage and normal PLAY isolation. TECH_PASSED:43 suites,85+15 live GUI checks; evidence TRAINING.md / WORK_LOG.md / training_results.json.

- [ ] VIRIDIAN-01 V0–V7 source audit/catalog verification then full fourth-hero integration, data-defined Control Mage kit, actual source side-view body animation, private source effects/audio, automated compatibility and actual Launch proof. V8 human acceptance remains pending.

- [ ] GRAVESHADE-01 PLAYABLE_TECH_TESTED: fifth ADC with actual Punisher body/VFX/SFX and full Basic/J/K/L/I;77currentLaunchGUIchecks,46suite regression and600.012s30/60/120mobsoak pass. Archive verification T01 partial (attachment transfer failed); human visual/listening approval and high-load performance follow-up pending. Doom Basic VFX reduction included. Evidence: reports/graveshade_tests.md / graveshade_blockers.md / docs/GRAVESHADE.md. No QA media exports.

- [ ] COMBAT-VFX-01 DEPLOYED_TARGETED_TESTS_PASSED: Doom per-ray active hit windows and compact Punisher explosions; current Launch79/81checks pass,45distinct regression suites pass. Bound-offers suite final result not captured after transport disconnect; direct visual acceptance pending. Evidence: reports/doom_punisher_vfx_fix.md.

- [x] DOOM-AUDIO-01 TECH_PASSED: supplied replacement Doom voice plays in parallel with original0.65s ray windup; stationary through ray completion only. Final current audio21headless/23rootGUIchecks pass; same runtime Viridian77/movement12/Training85checks pass. Human listening approval pending. See DOOM_ULTIMATE_AUDIO.md.

- [ ] TOFU-01 PLAYABLE_TECH_TESTED: sixth Tofu with actual source Basic/J/K/L/I visuals and shared melee kit;88headless/88currentLaunchGUIchecks,8Python tests,12regression suites and30mobnative1080p smoke pass. Source voice listening/true4direction art/human approval/performance gate remain pending. Evidence: docs/TOFU.md and reports/tofu/20261018/tests.md.

- [x] UI-WINDOW-01 Restore native Windows minimize/maximize/close via decorated maximized startup; preserve1920x1080 viewport. Actual GUI5/5 checks passed; reports/native_window_gui.log.

- [x] ZONE-AIM-01 Nearest reachable enemy placement for remote ground DoT (Astra L, Viridian K, Tofu K, Graveshade K), both Manual/Auto; preserve static zones and other skill targeting.40actualGUI+48selection checks pass; reports/ground_zone_targeting.md (existing unrelated renderer diagnostic recorded).

- [x] UI-POLISH-01 Presentation-only graphics/UI/UX polish: main menu, character select, settings, run HUD with dedicated boss bar, upgrade card kind tags, announcement banner, training panel placement, multiplayer host/join and lobby. No playable-character change. Evidence: WORK_LOG.md (2026-10-21 UI-POLISH-01 / PERF-01).

- [x] PERF-01 Presentation frame-time work: repaint only on state change for hitbox ring, actor overlay, enemy sprite and actor transform; pooled reusable damage captions instead of per-hit Label allocation. Evidence: WORK_LOG.md (2026-10-21 UI-POLISH-01 / PERF-01).

- [x] UI-HUB-01 Character hub: the main-menu CHARACTER page becomes a read-only information page and the playable hero is picked in a dedicated hub (animated portrait + short name + type only) opened by PLAY / MULTIPLAYER / TRAINING. Shared `HeroRoster` is the single source for roster order, loadout ids and class labels; the hub pick is carried into multiplayer through `MultiplayerCoordinator.local_character` instead of forcing Astra. No character data, sprite, animation, stat, skill or loadout change. Evidence: WORK_LOG.md (2026-10-21 UI-HUB-01).
