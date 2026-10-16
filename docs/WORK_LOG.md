# Implementation work log

## Environment / 2026-10-15
- Workspace: `D:\SelfProject\RougeLite`; Windows / PowerShell; Git CLI present, directory is not a Git repository. No commit created.
- Read complete handoff in README order: Decisions, Architecture, Gameplay, Tasks, Agents.
- Incoming documents were at repository root. Copied byte-for-byte to canonical `docs/`; retained originals, copied agent rules to `AGENTS.md`. Future progress updates use `docs/04_TASKS.md` only. Root handoff files remain historical inputs.
- Found existing Godot ZIP in user Downloads; console wrapper alone could not run because companion executable was missing. Extracted existing archive to ignored `tools/godot/`; no download/install or asset dependency added.
- Scope: M0 only. LOCKED requirements untouched. No gameplay/augment executor claimed implemented.

## M0-01 - project boot
- Intent: PC Godot/GDScript project, Compatibility renderer, main scene, placeholder menu; only Settings and Content autoloads. D-016, architecture invariant 7.
- Files: `project.godot`, `scenes/bootstrap/main.tscn`, `scripts/app/{settings,content_registry}.gd`, `scripts/ui/foundation_menu.gd`, `.gitignore`.
- Verification planned: engine version, clean headless editor import, main-scene smoke boot. Content registry and settings are foundation boundaries to be filled by M0-02/M0-05.
- State: in progress; evidence follows after execution.

- M0-01 verified: Godot 4.7.2.stable.official.ed1daf0bf; clean headless import and BOOT_OK (exit 0). Evidence: [import](evidence/m0-01-import.log), [boot](evidence/m0-01-boot.log). Initial attempt could not write user profile directories; portable marker plus process-local APPDATA inside workspace resolved this without elevation. State: [x].

## M0-02 - typed content
- Intent: typed definitions and read-only registry snapshots, validate IDs/references/ranks/numerical bounds/cycles before boot. No gameplay execution or fake capability support. Fixture definitions are explicitly not playable content. Tests planned for valid Resource roundtrip and negative cases. State: in progress.

- M0-02 verified: 27 checks / 0 failures; clean import. [Content tests](evidence/m0-02-content.log), [import](evidence/m0-02-import.log). Deep-copy isolation confirmed for nested rank/stat Resources, validation rejects duplicate IDs, missing references/ranks, bounds, unsupported capabilities and cycles. Godot self-typed exported dependency array initially leaked its GDScript at exit; changed only graph edge storage to Array[Resource], with concrete type checked by registry traversal. No gameplay/schema ownership change. State: [x].

## M0-03 - deterministic run foundation
- Intent: run-owned state, reproducible independent RNG streams, visible seed. Fixed DEMO seed 20261015, no global random. Tests: same seed/state, stream isolation, state restore and separate runs. State: in progress.

- M0-03 verified: 34 checks / 0 failures; seeds 0/20261015/-42/INT64_MAX; independent named sequences and exact continuation on restore; partial restore atomic rejection. Debug seed visible via RunRoot state summary in menu, main scene boot clean. [RNG tests](evidence/m0-03-rng.log), [import](evidence/m0-03-import.log), [boot](evidence/m0-03-boot.log). State: [x].

## M0-04 - reproducible local test runner
- Intent: native headless harness launches isolated suites and scene smoke; local PowerShell verifies import/parse/boot and actual failure exit. Scripts must fail on engine diagnostics even if native exit is zero. No CI-provider dependency. State: in progress.

- M0-04 verified: local script exit 0; 3 suites / 62 assertions, independent GDScript parsing and smoke boot clean; deliberate failure returned 1. Command: pwsh -NoProfile -File tools/test.ps1. [Suite log](evidence/m0-all-tests.log), [negative harness log](evidence/m0-expected-failure.log). Found check-only scripts do not resolve autoload global identifiers; switched to explicit typed scene-root service lookup. State: [x].

## M0-05 - persistent controls/settings
- Intent: WASD, J/K/L/I, Esc defaults; conflict-safe remap through InputMap, Auto/Manual persisted separately from run data in user://settings.cfg. UI sends settings commands only. Default Auto is provisional UI choice, not a new LOCKED requirement. Tests: real separate-process write/restart/read, invalid data, collisions, saving failure, UI event dispatch. State: in progress.

- M0-05 verified: 32 settings checks / 0 failures, plus two child-process write/read assertions. Defaults map WASD/J/K/L/I/Esc through physical keys; valid rebind J->U is persisted with Manual mode and reloaded in a NEW engine process. Duplicate gameplay keys, invalid modes/types/schema and reserved pause are rejected. Saving to a missing directory returns an error and leaves in-memory binding/mode unchanged. Scene tests dispatch InputEventKey events and verify duplicate rejection, Esc cancellation, successful rebind labels and mode selection. State: [x].
- Files: `scripts/app/settings.gd`, `scripts/ui/foundation_menu.gd`, `tests/unit/test_settings.gd`, `tests/integration/settings_restart.gd`, updated scene smoke/harness. Settings schema v1 contains only version/mode/physical key bindings; no save-run scope added.
- A parse attempt exposed nonexistent `KEY_MAX` in Godot; replaced with engine key-name roundtrip validation. The strict runner caught diagnostics even though the editor process returned 0. Final parse is clean.

## Final M0 acceptance / 2026-10-15

Command executed from workspace:

```powershell
pwsh -NoProfile -File tools/test.ps1 -Graphical
```

| Task | Verified implementation | Evidence |
|---|---|---|
| M0-01 | Godot project, bootstrap, placeholder menu; Settings/Content only autoloads; clean startup | [Final import](evidence/m0-final-import.log), [boot](evidence/m0-final-boot.log), [engine](evidence/godot-version.log) |
| M0-02 | Typed character/skill/rank/augment/effect/map/enemy/boss Resources; private deep copies; ID/reference/value/cycle validation | [Content suite: 29 checks](evidence/m0-all-tests.log) |
| M0-03 | Run-owned RunState and five independent named RNG streams; state restore and debug seed | [RNG suite: 34 checks](evidence/m0-all-tests.log), [graphical smoke](evidence/m0-graphical-smoke.log) |
| M0-04 | Local runner, import + all 28 GDScripts independently parsed, isolated suites, smoke boot, failing-fixture propagation | [Full command transcript](evidence/m0-verification-transcript.log), [expected assertion failure / exit 1](evidence/m0-expected-failure.log) |
| M0-05 | InputMap defaults, conflict-safe persisted remap, Auto/Manual UI and separate-process restart verification | [Settings suite: 32 checks + restart workers; scene smoke: 1 aggregate check](evidence/m0-all-tests.log) |

- Final normal suite: **4 suites / 96 top-level checks / 0 failures**, plus two successful child-process assertions. Final local script exit **0**. Intentional negative fixture actually compares 1 vs expected 2; its exit **1** propagates through the normal suite aggregator (not a shortcut success/failure flag).
- No engine warnings, parser errors, script errors or leaked-resource diagnostics in final normal import, tests or boot.
- Additional graphical runtime test passed on NVIDIA RTX 3050 Laptop GPU / OpenGL 3.3 Compatibility, NVIDIA 592.82. Internal frame `docs/evidence/m0-menu.png` was visually inspected: text and controls fit the 1152x720 viewport, mode/seed/rebind labels readable. This was automated scene/input testing and visual inspection, not a manual combat playtest or performance benchmark.
- Environment: [environment log](evidence/environment.log); Godot `4.7.2.stable.official.ed1daf0bf`, Windows build 26200, PowerShell 7.6.5, Git 2.55.0. No Git repository existed, so no commits were created.
- M0 exit gate: **PASS**. Canonical M0 tasks checked only after corresponding verification. M1-M5 remain unchecked.

## Boundaries / known limitations / next work

- No blocking M0 defects observed. There is no player movement/combat, real skill executor, augment mechanic, XP loop, boss, arena generation or standalone Windows export yet. These remain M1-M5.
- The catalog contains one map DATA definition; it is not a generated/playable arena. Other Resources are exercised through explicitly schema-only fixtures. Executors advertise no capabilities until real operations are implemented in M2; no tag-based fake support was added.
- Universal Augment prerequisites/scopes/effect values are data contracts only in M0, with no character-dependent upgrade logic. Runtime definitions stay isolated from run state.
- No LOCKED rule or balancing value changed. `FOUNDATION` is a non-gameplay preview phase. Auto default and fixed preview seed are implementation defaults, not new user commitments.
- Local launcher redirects APPDATA only for its process; launching Godot directly can read a different settings directory. RNG replay requires this engine version and matching content/state/seed.
- No paid/third-party character art was downloaded. Art/joint animation decisions are deferred; they do not block Foundation.
- Next unchecked task: **M1-01** (normalized WASD physics movement/collisions), followed by M1 combat/EXP in backlog order. Stop here per user's current M0 scope.

## GitHub publication request / 2026-10-15
- User requested push and selected creation of a private repository named RougeLite. No remote repository was created or push claimed.
- Git Credential Manager noninteractive lookup found no usable GitHub session. Browser-control runtime failed to initialize; GitHub plugin discovery confirmed it is not connected.
- `git init -b main` succeeded. `git add` / `git commit` failed: cannot create `.git/index.lock` (Permission denied). No attempt to bypass the filesystem restriction. Source remains local and intact; publication is blocked on Git metadata write access plus GitHub authentication.

## M1-01 - movement/collision
- Scope: D-003 normalized WASD through shared MovementController, CharacterBody2D player and authored static test geometry; no random map generation or gameplay balance changes. Astra movement values are data Resources.
- Files: actors/movement_controller.gd, player_actor.gd; world/arena_geometry.gd; characters/player.tscn; run/movement_lab.tscn; characters/astra_stats.tres; integration/test_movement.gd.
- Tests planned: eight-direction velocity, real InputMap movement displacement, physical obstacle and map-boundary collisions. State: in progress.

- M1-01 verified: 12 checks / 0 failures; exact command via tools/common.ps1: Godot --headless --path . --editor --quit, then --script res://tests/integration/test_movement.gd. [Import](evidence/m1-01-import.log), [movement](evidence/m1-01-movement.log). Physical WASD/collision tests executed, no warnings. State [x].

## M1-02 - actor lifecycle
- Intent: composable per-actor stats/health and weak-target enemy chase; definition Resources remain unchanged. HP state accepts resolved values; damage formula remains deferred to M1-04. Tests: real chase/collision, definition stats, single death notification. State: in progress.

- M1-02 verified: 5 checks / 0 failures. [Actor lifecycle](evidence/m1-02-actors.log), [import](evidence/m1-02-import.log). HP resolved-state commit used only to exercise lifecycle; combat subtraction is introduced solely in DamageResolver in M1-04. State [x].

## M1-03 - nearest valid targeting
- Intent: shared service validates team/liveness/range/deletion, tie-break by stable actor ID. Tests: empty, exact range, outside, dead/allied/freed/queued targets and ties. State: in progress.

- M1-03 verified: 9 checks / 0 failures; [targeting](evidence/m1-03-targeting.log). Initial negative fixture constructed a NEW TypedArray containing an already-freed object; Godot rejected construction before the service ran. Corrected fixture to retain the candidate array across target deletion, which verifies the real stale-reference path cleanly. State [x].

## M1-04 - shared damage/status pipeline
- Intent: one resolver for both teams; physical/magic/true mitigation, seeded crit, FIFO shields, status and once-only kill events. Existing defense formula/caps remain as specified. Tests use actual Actor/Health instances and seeded RNG. State: in progress.

- M1-04 verified: 17 checks / 0 failures; [damage/status](evidence/m1-04-damage.log), [import](evidence/m1-04-import.log). One resolver handles both actor teams, statuses applied after damage, shields FIFO, no damage math in actors/UI. State [x].

## M1-05 - reusable basic attack strategies
- Intent: one AttackController, projectile/melee executors selected from content, one shared CombatService/DamageResolver. Astra/Vex/Boros basic-only CombatLoadoutDefinition resources are explicit projections; full CharacterDefinition active kits remain M3 (no fake active skills). Test each real physics projectile/melee hit plus cooldown and no-target behavior. Manual player QA will remain unchecked if not executed. State: in progress.

- M1-05 automated verification: 18 checks / 0 failures across all 3 loadouts using real swept-physics projectile hits and melee; [attacks](evidence/m1-05-attacks.log). Resource text Color constructor initially required numeric components; corrected authoring, final test clean. Manual play requirement not yet performed, so M1-05 checkbox stays unchecked pending manual QA. Implemented basic controller supports both modes identically (active skill mode is not consulted).

## M1-06 - XP/orbs and level transactions
- Intent: data-driven XP curve, single-collect orbs with magnet pickup, queued level transactions and HUD presentation. Tests: batched XP, sequential acknowledgements, paused pending choice, dead player and one-time orb collection. State: in progress.

- M1-06 domain tests passed: 10 checks / 0 failures, [progression](evidence/m1-06-progression.log). HUD/run integration remains to be verified with M1-07, so checkbox stays pending until that evidence exists.

## M1-07 - stat core offers and playable composition
- Intent: 8 data-driven repeatable stat cores, strict eligibility and 3 distinct seeded choices; UI dispatches commands while entire combat world pauses. Compose existing modules in a dedicated combat RunRoot. M1 slice explicitly ends at the first pending boss milestone rather than pretending boss combat exists. Full endless/boss loop remains M4. Tests: >100 levels, rank caps/duplicate selection, paused physics, death/retry and scene gameplay. State: in progress.

## Final M1 implementation verification / 2026-10-15

Executed from `D:\SelfProject\RougeLite`:

```powershell
pwsh -NoProfile -File tools/test.ps1 -Graphical -EvidencePrefix m1
```

Result: script exit **0**, **12 isolated suites / 215 top-level checks / 0 failures**, plus two successful separate-process settings assertions. All **70 GDScripts** parsed independently. Clean editor import, main scene boot and both graphical menu/combat tests. Expected negative fixture returned **1** through the same suite aggregator.

| Task | Implemented behavior / evidence | Status |
|---|---|---|
| M1-01 | 12 checks: normalized 8-direction speed, real InputMap displacement, collider and arena bounds | [x] |
| M1-02 | 5 checks: enemy definition stats, actual chase and one death event; runtime isolation | [x] |
| M1-03 | 10 checks: nearest, exact/outside range, strict near-equal distance, stable-ID tie, null/dead/allied/queued/freed references | [x] |
| M1-04 | 17 checks: shared physical/magic/true resolver, negative armor, seeded crit, FIFO shields, status/stagger and once-only kill | [x] |
| M1-05 | 18 automated checks: Astra/Vex physics projectiles, Boros melee, cooldown/no-target, immutable definitions. Explicit manual three-character play requirement remains unexecuted | [ ] |
| M1-06 | 10 domain checks plus scene HUD/orb tests: exact XP curve, multi-level queue, one collection, magnet, dead-state/boss-bank guard | [x] |
| M1-07 | 34 upgrade checks plus 11 scene checks: 8 stat cores on two different loadouts and incompatible/dead cases; 120 sequential levels each; caps; deterministic/distinct offers; full-world pause, card commit, death, retry | [x] |

Evidence:
- [Full import/parse/test transcript](evidence/m1-verification-transcript.log)
- [All suites and exact check counts](evidence/m1-all-tests.log)
- [Final import](evidence/m1-final-import.log), [main boot](evidence/m1-final-boot.log)
- [Failure propagation](evidence/m1-expected-failure.log)
- [Graphical menu](evidence/m1-menu-graphical.log), [graphical combat](evidence/m1-combat-graphical.log)
- Internal verification frames `m1-combat.png`, `m1-upgrade.png` and menu frame visually inspected: correct 1152x720 layout, three readable distinct cards, actors/obstacles/HUD visible. Screenshots are not part of the source publication set.

Implementation mapping / files:
- `scripts/actors`: Actor + runtime stats/health/shields/status, PlayerActor and EnemyActor; `scripts/combat`: TargetingService, DamageResolver, CombatService, AttackController and swept-physics CombatProjectile. Both factions use the same resolver/controller strategies.
- `scripts/progression`: LevelManager transaction/choice acknowledgement and XpOrb; typed progression/spawn Resources now indexed/validated with IDs.
- `scripts/augments`: global stat eligibility, instances, additive baseline modifiers and seeded weighted sampling without replacement. No character ID/name branch in shared combat/augment code. Mechanic effects still M2.
- `scripts/core/combat_run_root.gd`: a per-run composition root derived from the existing RunRoot boundary; owns runtime systems, phase and encounter-preview boundary. UI rules stay in domain services; UI only presents state and sends commands.
- `scripts/ui`: main menu launch buttons, RunHud and RunPresentation. Full character kit selection/preview still M3, release UX M5.
- `content/characters/*_loadout.tres`: explicit basic-only typed projections, referencing shared stat/skill definitions; do not bypass full CharacterDefinition validation or fabricate unimplemented actives.
- `content/augments/stats`: eight actual reusable stat effects. Max HP maintains current HP ratio; damage/speed bonuses add against baseline; crit/CDR/move/attack frequency caps retained. Pickup-radius soft cap remains optional/deferred, no undocumented balance change.
- `scripts/world`: authored connected open geometry and bounded safe spawn sampler. Random map templates/navigation remain M4. Spawn rejects unsafe/offscreen/overlap candidates, defers if none.

Issues found and resolved during execution:
- New TypedArray construction with a freed object was an invalid test setup; the stale-array test now retains the original array across deletion.
- Godot text Resources require numeric `Color(...)` components; corrected generated authoring files.
- A card label used unsupported `%g` formatting. The quality gate caught engine errors despite all scene assertions passing. Replaced it with authored numeric descriptions, reran the scene and full suite cleanly.
- Input/schema validation strengthened for spawn safety, progression lifetime, actual executor strategy and stat cap finiteness. Unsupported mechanic capabilities still fail closed.

Manual QA limitation:
- Browser control could not start (`cannot locate required Windows platform directory`). Native `@oai/sky` import succeeded, but app discovery failed: `failed to launch codex app-server: program not found`. Therefore no native-window manual play is claimed. Godot headless physics, input events, real graphical rendering and frame inspection ARE verified.
- M1-05 remains unchecked exactly because its manual-play step is pending. M1 is implemented as a playable basic combat slice, but the full formal M1 exit gate is not claimed passed. Next gate: manually play each basic loadout and verify nearest-in-range/cooldown/input behavior; then proceed M2.

Preview scope:
- Play Astra/Vex/Boros from main menu; WASD, auto basic, chasing chasers, EXP orbs, 3-choice global core upgrade, Esc pause/resume, death/retry/menu.
- At level 10, the level's core is offered first, then the preview stops at `MILESTONE_PENDING` with an explicit message. It does NOT award boss victory or transition maps. This is an incomplete encounter boundary until M4, not a change to D-012/D-013 or a claimed full endless game.
- J/K/L/I unlock/casting and mechanic augments remain M2/M3. Core CDR is persisted into runtime stats for future active skills and does not affect basics; its card says so. Geometry and characters are temporary local shapes.
- No Windows EXE release export or performance/20-minute soak claim. M5 remains the packaged demo milestone.

GitHub / commits remain blocked:
- User chose private repo `RougeLite`, but no authenticated GitHub credential is available. No remote repo was created.
- Git metadata cannot be staged: `fatal: Unable to create 'D:/SelfProject/RougeLite/.git/index.lock': Permission denied`. There are no commits or pushes. No workaround around protected metadata was attempted.
- Source, tests, docs and evidence are ready locally. Engine/cache/user settings/internal workspace configuration are excluded from the intended publication set. Publication needs authenticated GitHub access AND a terminal/context allowed to write this repository's Git metadata.

## Windows launcher compatibility fix / 2026-10-15
- User's terminal cannot resolve `pwsh`. The previous launch instructions unnecessarily assumed PowerShell 7 was installed/on the user's PATH.
- Added root `Launch.cmd` to start the existing portable Godot directly, forwarding engine arguments and preserving process-local APPDATA/settings location. No installation or execution-policy change required. Updated README launch instructions; automated test harness still explicitly requires PowerShell 7.
- Verified from Windows PowerShell: `powershell.exe -NoProfile -Command '& ".\Launch.cmd" --headless --quit-after 3; exit $LASTEXITCODE'`. Exit 0, RUN_FOUNDATION and BOOT_OK milestone=M1, no errors/warnings. [Evidence](evidence/windows-powershell-launch.log).
- No gameplay/architecture/LOCKED requirement changed. Full gameplay suite was not repeated for this launcher-only change.

## M1 user acceptance / 2026-10-15
- User explicitly approved the milestone: "duyet M1". M1 is accepted on that basis, with the existing implementation and 215-check automated evidence retained.
- This acceptance closes the previous outstanding M1 acceptance gate and supersedes its pending status in the task ledger. It is NOT a claim that the assistant completed native manual play, nor that the user reported each individual manual step.
- No gameplay/architecture requirements were changed by acceptance; previous tool limitations remain historical facts.

## M2-01 - skill lifecycle foundation
- Intent: implement D-007/D-008 free slot unlocks at 3/6/9/11, rank caps 4/4/4/3, independent owner/rank/cooldown state, and unlock phase before level-up offer dispatch. No new balancing defaults.
- Files: `scripts/combat/skill_runtime.gd`, `scripts/combat/skill_controller.gd`, `scripts/progression/level_manager.gd`, `tests/unit/test_skill_lifecycle.gd`, `tests/run_all.gd`.
- SkillRuntime keeps private detached definition snapshots; mutation of original definitions or returned copies cannot affect another runtime. Cooldown only commits after a future executor accepts a cast; it is not an ability executor. Readiness requires unlock, cooldown never runs during a paused simulation, CDR capped at 60%.
- SkillController validates exactly four ordered unique active definitions and rejects partial invalid configuration. No character IDs/names enter lifecycle logic. `LevelManager.level_entered` is the explicit domain-unlock phase before `level_applied`/offer presentation; existing XP transaction semantics retained.
- Focused verification: [44 lifecycle checks, 0 failures](evidence/m2-01-skill-lifecycle.log), [clean import](evidence/m2-01-import.log). Regression in progress; checkbox remains pending until it completes.
- Schema-only fixture skills are used to exercise actual lifecycle logic; no unimplemented executor/capability or player-facing active skill is claimed. Wiring real actives into the playable scene remains M2-02/M2-03 and full content M3.

- M2-01 verified: focused suite **44 checks / 0 failures**; regression **13 suites / 259 top-level checks / 0 failures** (plus settings restart workers). Independent `--check-only` passed for both new runtime/controller scripts, LevelManager and lifecycle test. Main scene boot clean. All executed with Godot 4.7.2 stable via tools/common.ps1, exit 0.
- Exact regression command: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_all.gd`; parse command: `--headless --path . --check-only --script <each changed script>`; startup command: `--headless --path . --quit-after 3`. APPDATA set process-locally by existing helper.
- Evidence: [regression](evidence/m2-01-regression.log), [boot](evidence/m2-01-boot.log), [SkillRuntime parse](evidence/m2-01-parse-skill_runtime.log), [SkillController parse](evidence/m2-01-parse-skill_controller.log), [LevelManager parse](evidence/m2-01-parse-level_manager.log), [test parse](evidence/m2-01-parse-test_skill_lifecycle.log).
- M2-01 state: [x]. No UI/gameplay rendering changes, so graphical checks were not repeated. The playable slice still exposes basic attacks only; lifecycle services are prepared for actual cast integration next. Next task: M2-02, then executor protocols and capability verification M2-03. GitHub/commit blockers unchanged.

## M2 completion / 2026-10-15
- User requests all remaining M2 tasks. Selected M2-02 first: one Auto/Manual command path, lifecycle validation and InputMap routing. Files: SkillController, CastIntent, SkillInputRouter and executor protocol adapter. Test actual damage via existing melee executor, not a success stub.
- User resolved missing Split rank-5 catalog value: 6 extra shots at 65% damage. Record as explicit selected value; prior rank data unchanged.

### M2 implementation report — M2-02 through M2-08

Intent: finish the Universal Augment System and integrate it into the existing playable preview without changing LOCKED rules. Implementation follows M2 dependencies: cast commands, executable adapters, bounded envelopes, bound offers, mechanic effects, then combination/scene regression.

Files and boundaries:
- `scripts/combat/{cast_intent,skill_controller,skill_runtime,combat_service,cast_budget,projectile,timed_effect,combat_flash,attack_controller}.gd`; `scripts/core/{combat_context,combat_run_root}.gd`; input router and actor motion/shield presentation.
- `scripts/data/{effect_executor_definition,mechanic_effect_definition,combat_limits_definition}.gd`; validation extensions for skill/loadout/augment/status definitions. No new autoloads. No separate damage formula or character-ID switch in shared mechanics.
- `scripts/augments/{augment_manager,eligibility_evaluator,offer_generator,upgrade_option}.gd`: per-target ranks, capability-backed eligibility, deterministic sampling, numeric current/next descriptions and dead-owner rejection.
- Twelve mechanic `.tres` files, twelve baseline active definitions, loadout/catalog references and editable combat safety config. Reproducible content authoring: `tools/author_m2.gd` (authoring only; runtime loads Resources).
- HUD/menu/upgrade presentation, seven new focused suites, suite registration and test-helper diagnostics/timeout handling. Root README updated for M2 controls and scope.
- Interface/ownership implementation mapping: [ADR-2026-002](adr/ADR-2026-002-m2-universal-runtime.md). No LOCKED requirement changed; settings remain schema v1.

Task verification mapping:
- **M2-02**: Auto/Manual share request_cast; remappable InputMap commands, actor/state/stun/pause/cooldown validation. [Cast checks](evidence/m2-02-cast-modes.log); actual three-loadout scene checks in final regression.
- **M2-03**: actual projectile, area ticks, instant beam, timed shield, collision-aware dash and status adapters; false capability/geometry claims rejected. [103 shared augment checks in final regression](evidence/m2-all-tests.log), final shared-effect matrix and event-envelope suites.
- **M2-04**: frozen modifier snapshots, unique collision/event/parent IDs, live shared remaining budget, deterministic queue and ordering, PRIMARY_ONLY/ONCE_PER_ROOT_CAST/ALLOW_SECONDARY policies. [Envelope checks](evidence/m2-event-envelope.log), combination suite and configurable limits.
- **M2-05**: target-bound options, per-target caps, skill ranks, 3 distinct valid choices; 200 seeded offers per loadout and stats-only fallback after all mechanic/skill caps. Fresh unlock eligibility precedes same-level offers. Final bound-offer suite.
- **M2-06**: Split/Multishot/Pierce/Echo/Area Expand use shared adapters across compatible kits; Split rank5 = 6 extra shots at 65% (user selected), rank6 rejected. Echo once at 0.6s without another cooldown.
- **M2-07**: Explosion/OnKill/Refund/Reflect/DashShockwave/Execute/Homing; trigger, damage, absorption, geometry, seeded probability and incompatible binding coverage. Reflect boss cap 1% maximum HP/hit (user selected). Shared matrix covers behavior on both compatible kit definitions, not only eligibility.
- **M2-08**: Astra J and Vex L four-way Split+Multishot+Echo+Explosion produce 42 initial shots + 6 echo shots, settle fully, obey depth<=3/procs<=32/projectiles<=64. Adversarial overflow truncates at64; overlapping lethal shots emit one kill per target. Acquisition order does not change geometry/damage.

Executed command forms (Godot 4.7.2 stable, Windows; helper sets only process-local APPDATA):
- `& ./tools/test.ps1 -Graphical -EvidencePrefix m2` (full import, 89 independent script checks, suites, boot, deliberate-failure harness, real-renderer menu/combat/M2 scenes).
- `. ./tools/common.ps1; $engine = Resolve-ProjectGodot ''; Set-ProjectUserData; Invoke-CheckedGodot $engine @('--headless','--path',$ProjectRoot,'--script','res://tests/run_all.gd') 'm2-all-tests.log' -TimeoutSeconds 180` (final regression after follow-up fixes).
- Follow-up `--check-only --script res://<changed-file>` checks recorded as `m2-final-parse-*.log`; final changed scripts are also exercised by the regression/graphical scene.
- `--path . --editor --quit` for real-renderer editor import smoke; `--path . --script res://tests/scenes/test_m2_run.gd -- --capture-m2` for rendered scene checks.
- `powershell.exe -NoProfile -Command '& ".\Launch.cmd" --headless --quit-after 3; exit $LASTEXITCODE'` verifies launch without pwsh in the user's terminal.

Issues found and resolved during verification:
- Modifier snapshot initially used Vector2 (32-bit components), causing exact Reflect damage drift. Replaced with full-precision GDScript float arrays; exact-damage tests retained.
- Expanded aggregate exceeded the old 45-second whole-process deadline. Aggregate deadline is explicitly 180 seconds; individual commands remain45. Timeout now preserves stdout/stderr evidence. Gameplay budgets were not changed.
- Editor `--quit-after 3` interrupted filesystem scan and correctly failed the warning gate. Replaced with `--editor --quit`, which waits for import and exits cleanly.
- Numeric tooltip used unsupported `%g` formatting; graphical diagnostics correctly rejected the run despite exit0. Fixed with supported numeric formatting and added coverage for every mechanic rank description.
- Refined graphical fixture placement to use a clear target point/line of sight, rather than relocating the fixture into authored obstacle geometry. This is a test-fixture correction, not a spawn-rule change.

Known scope/verification limits:
- Baseline skills demonstrate M2 adapters; complete rank-specific character kit effects, timed Vex bursts, Astra secondary rank effects, buffs and Boros transformation remain M3. Boros I is explicitly pending/unsupported, not a fake successful cast.
- Normal preview still stops after the level-10 choice before the unimplemented first boss (M4). Level11 lifecycle and rank3 ultimate cap are automated fixtures, not a claimed playable boss victory.
- Visuals remain local geometric placeholders. Real renderer screenshots were reviewed; no assistant-performed native manual play, performance benchmark, standalone export or full endless-run acceptance is claimed.
- GitHub authentication/Git metadata write blockers from the earlier session remain; no commit/push claimed.
- Final totals and task checkbox update follow only after the last regression completes.


## Final M2 verification

Date: 2026-10-15. Task states: **M2-01 through M2-08 [x]**. No high-severity open M2 failure remains in the executed checks.

- Final regression: **20 suites / 616 top-level checks / 0 failures**, plus two isolated settings restart worker checks. Exact result: `RESULT suites=20 failures=0`, exit0. [Final aggregate evidence](evidence/m2-all-tests.log).
- M2-focused suites: cast modes14; universal augments103; combinations141; bound offers15; three-loadout scenes54; event envelopes16; shared effect behavioral matrix14. Earlier lifecycle44 remains covered. The matrix includes actual swept Pierce on Astra J/Vex L, actual expanded collision on Astra L/Boros J, absorbed Reflect on Astra K/Boros K and endpoint shockwave on Vex K/Boros L; incompatible cases are checked for all12 mechanics.
- Full verification script completed clean import, **89 independent GDScript parses**, baseline/expanded regression, boot, deliberate-failure proof and real-renderer checks. [Full verification transcript](evidence/m2-verification-console.log), [import](evidence/m2-final-import.log), [expected failure](evidence/m2-expected-failure.log). Later owner/envelope/tooltip refinements were independently parsed where changed and followed by the final20-suite regression above. Final tooltip formatting is covered for every mechanic rank.
- Final real-renderer M2 scene: **55 checks / 0 failures**, exit0, no warnings/errors. [Graphical evidence](evidence/m2-active-graphical.log). Actual OpenGL Compatibility device: NVIDIA GeForce RTX3050 Laptop GPU. [Clean editor smoke](evidence/m2-editor-smoke.log). These are automated rendering checks, not a human manual-play claim.
- Reviewed actual rendered [gameplay frame](evidence/m2-gameplay.png) and [bound upgrade frame](evidence/m2-upgrades.png): readable mode/key/cooldown HUD, geometric shield/area/projectile effects, three distinct cards identifying skill, current/next rank and numeric effect values. Fixture target placement is collision-clear and has line of sight.
- Windows PowerShell5 launch via Launch.cmd remains exit0 with `BOOT_OK milestone=M2`, no pwsh dependency for launching. [Launcher evidence](evidence/m2-windows-launch.log).
- Final diagnostic scan across aggregate, graphical M2 scene, editor and launcher logs found **0** ERROR/SCRIPT ERROR/WARNING/FAIL markers. Deliberate-failure fixture remains intentionally failing with exit1, as expected.

Playable M2 scope: select any of three loadouts, move/fight/collect XP, unlock baseline J/K/L at3/6/9, use Auto or remapped Manual commands, bind mechanic/stat/rank cards, pause, die and retry. Frozen cast modifiers and root budgets remain independent of content Resources and acquisition order. Slot I unlock/rank lifecycle is tested at11, while normal preview still respects the pending first-boss boundary at10.

Next milestone: **M3-01**, full Astra ranks/kit effects, then Vex/Boros and full selection/tooltips. M3/M4/M5 remain unchecked. No boss victory, polished animated characters, endless progression, release EXE or GitHub push is claimed by M2 completion.
## M3-M5 autonomous implementation / 2026-10-15
User authorizes completing M3 through M5, self-testing/fixing and recording unanswered questions without waiting while travelling. Keep LOCKED rules unchanged. First selected task M3-01: rank behavior Resource graph and generic runtime hooks; then M3-02/M3-03 data, tests, UI. No task checked until its executed verification passes.

## Final M3-M5 demo verification

Date:2026-10-15. Authorization: user requested autonomous M3-M5 completion, self-testing/fixing and recording unanswered questions while travelling. All LOCKED controls, unlocks, rank caps,3-choice upgrades, universal augment semantics and level-driven boss/map rules remain intact.

### Implemented scope and per-task evidence

| Tasks | Implementation | Executed evidence |
|---|---|---|
| M3-01 | Astra complete rank data: root/projectile/pierce/death pulse, shield/move/block/expiry, field radius/duration/slow, beam/burn | full-kits37 + native-edge6 suites in final aggregate |
| M3-02 | Vex timed barrage/crit pierce, roll buff/double next basic/one kill refund, boss bonus/mark, timed storm/budgeted bounce | full-kits37, native-edge6 and reusable modifier regressions |
| M3-03 | Boros HP-scaled slam/second ring, reduction/reflect/heal shield, charge/stun/path trail, HP/range/pulse transformation without ratio exploits | full-kits37/native-edge6, exact damage and temporary stat tests |
| M3-04/05 | Three selection cards show role/HP/speed/full skill names; all4 runtime slots, remappable controls, disabled lock/cooldown buttons, numeric skill tooltips and status/shield/transform indicators | three-loadout scene54 checks, real-renderer scene55 checks, menu screenshot |
| M4-01/02 | Three seeded map templates, reserved escape corridors, flood-fill reachability/open fallback, cached flow-field navigation, safe/navigable/offscreen spawn sampling and adaptive40→110 population cap | map/boss24 checks including15 deterministic layouts; spawn regression; hazard6 checks |
| M4-03 | BossGate pending/active/victory/transition/dead states, exact10-level milestones, one instance, XP banking and sequential post-gate offers | endless198 checks |
| M4-04/05 | Stone shockwave/cone and Ember laser/phase lanes/summons, telegraphs, phase scaling, shared damage | real-renderer24 checks including actual WASD-driven PlayerActor movement dodging each telegraphed attack; stationary control takes exact24 damage. This is scripted input-driven playtesting, not human manual acceptance |
| M4-06/07 | Delayed victory adjudication gives death priority; map bag avoids repeats; keep permanent upgrades/ranks and HP ratio, clear temporary state, recover15% HP/reset cooldowns/2s immunity; scalable subsequent bosses | all3 characters reach41 through4 real boss deaths and5 map visits each, bank release/duplicate/race tests |
| M5-01/02 | Pause/resume/retry/menu, remapping and mode switching in pause, fullscreen toggle, readable scaling, named bound cards, rerolls, jointed original placeholders, shield/attack/boss/damage feedback, synthesized tones and summary | native-renderer menu/M2/release presentation frames; scene/settings restart suites |
| M5-03 | Profile100 real enemy actors +300 moving swept projectiles, preserve full fixture load, shared navigation/rank snapshot optimization, no critical stall/return live node count to baseline | performance5 checks; measured frame timings below. Stable60FPS target NOT achieved |
| M5-04 | Full deterministic regression, negative harness proof, graphical checks and a prepared3-character manual QA tour |25 suites/887 checks; MANUAL_QA.md. Human manual tour remains unexecuted/unclaimed |
| M5-05 | Windows exported PCK + portable official runtime, launcher/readme, exact engine/third-party notices, source rights-reserved file, source archive tool; no source tree/Godot install needed to play | packaged smoke and fresh extracted smoke both3 profiles/3 boss victories, exit0, source test-file namespace excluded |
| M5-06 | Actual secondary Web export attempt using a preset | expected exit1: matching Web templates absent. No Web build claimed; Windows is complete independently |

Files: rank behavior Resource and RankEffectSystem; Actor temporary categories; shared skill/combat/projectile changes; full skill `.tres` rank data; BossGate/BossActor/BossTelegraph; MapLayoutGenerator and arena flow field/hazards; two boss and two extra map definitions; HUD/menu/presentation/audio/jointed visuals; release smoke, packaging/source archive/export presets, dedicated tests and notes. Full mapping is [ADR-2026-003](adr/ADR-2026-003-full-demo.md).

### Final executed results

- [Final aggregate](evidence/m5-all-tests.log): **25 suites /887 top-level checks /0 failures**, plus2 settings restart worker checks. Final focused kit suite37, native edges6, maps/bosses24, endless198, hazards6. Existing M0-M2 suites remain covered.
- [Parse summary](evidence/m5-parse-summary.log): **105 scripts independently checked**, exit0, one `m5-final-parse-*.log` each. Final WASD-test refinement was also compiled/executed on the actual renderer.
- [Real-renderer WASD boss/map test](evidence/m4-wasd-dodge-graphical.log):24 checks,0 failures. Input.action_press drives the real PlayerActor/MovementController and hit shapes; no direct target relocation substitutes for the dodge. This distinguishes scripted playtesting from human play.
- [Graphical active scene](evidence/m5-active-graphical.log):55 checks,0 failures; [release presentation](evidence/m5-presentation.log):1 check,0 failures. Reviewed [menu](evidence/m0-menu.png), [boss/rig/telegraph](evidence/m5-boss.png), [pause controls](evidence/m5-pause.png) and upgrade frames.
- [Packaged smoke](evidence/m5-release-smoke.log) and [fresh extracted package smoke](evidence/m5-extracted-smoke.log): each prints `RELEASE_SMOKE_OK profiles=3 boss_victories=3`, exit0. Extracted folder contains runtime/PCK/launcher/notices only; explicit resource path points at that folder and --pack-check proves source test files are unavailable. This is accelerated acceptance, not a natural-play balance run.
- [Final boot](evidence/m5-final-boot.log): `BOOT_OK milestone=M5`, content stamp `endless-demo-v1`, exit0. [Editor smoke](evidence/m5-editor-smoke.log) is clean. The final content stamp is metadata-only; gameplay assertions above cover the same final authored definitions/logic.
- [Deliberate harness failure](evidence/m5-expected-failure.log): intentional assertion returns1 and aggregate failures1, as expected. Normal diagnostics remain strict.
- Final scan of aggregate, package, extracted package, boot/editor, profile and graphical boss/presentation logs found **0 ERROR/SCRIPT ERROR/WARNING/FAIL** markers. Expected negative/Web attempt logs are deliberately excluded from the success scan.

Exact command forms:
```
& ./tools/test.ps1 -Graphical -EvidencePrefix m5
Godot --headless --path . --script res://tests/run_all.gd
Godot --headless --path . --check-only --script res://<each of105 scripts>
Godot --path . --script res://tests/integration/test_maps_and_bosses.gd
Godot --path . --script res://tests/scenes/test_performance.gd -- --capture-profile
Godot --path . --script res://tests/scenes/test_release_presentation.gd
& ./tools/package.ps1
EndlessSurvival_console.exe --headless --path <extracted-windows-folder> -- --smoke-release --pack-check
```
Use tools/common.ps1 to resolve the exact Godot4.7.2 binary and process-local writable APPDATA. Export/parse/aggregate/package phases were ultimately run sequentially, preserving clean diagnostics. The full script initially caught follow-up failures; final aggregate/focused/graphical/package logs above supersede intermediate failed transcripts. No failed gate was converted to success by ignoring diagnostics.

### Problems found and fixed

- Callback for charge trail referenced a freed TimedCombatEffect. Replaced with a Callable bound to the run-owned service; exact60+4×10 path damage passes.
- Auto self-target guard wrongly suppressed area/buff casts while shielded; range acquisition used rank1 values after rank-up. Guard now applies only to shield adapters; current rank's range/radius drives offensive targeting. Root blocks dash movement. Four new checks prove these conditions.
- Echo/Split scale native HP-based/delayed damage as well as flat damage; Echo+HP-scaled slam has an exact regression.
- Reflect could exceed the confirmed boss cap through outgoing damage/crit multipliers. Reflection now cannot crit/reapply outgoing-stat or mark scaling; tested under guaranteed crit/double damage.
- Packaged headless shutdown leaked dummy WAV playback references. Audio now avoids inaudible dummy-driver playbacks, explicitly stops/clears streams on exit; real renderer sound remains enabled. Final packaged/extracted runs have no leak warnings.
- A hand-edited hazard property preceded its script assignment in `.tres` and was not loaded. Restored script-first ordering, added a fail-fast hazard test and reran actual damage/pause/spawn checks.
- An overlapping export/editor operation caused an interim aggregate timeout; phases were rerun sequentially. No runtime deadlock is claimed or hidden. A brief host exec transport disconnect recovered on retry.
- External QA extraction locations (`D:\workspace` and sandbox-specific temporary paths) were denied by host permissions. No escalation/workaround attempted; fresh extraction under the allowed project builds/qa-extracted directory plus explicit resource-path/source-exclusion assertions verifies the distributable independently of source resources.

### Performance and remaining review

Measured on AMD Ryzen5 6600H / NVIDIA RTX3050 Laptop GPU, Windows OpenGL Compatibility. [Last full-load profile](evidence/m5-performance.log) uses60 rendered frames with100 actual enemies and300 actual swept projectiles throughout: frame minimum16.745ms, median28.776ms, p95 119.762ms; process/physics monitor median24.865ms. These are environment-specific short stress observations, NOT a stable60FPS or long-soak claim. Five safety/cleanup checks pass. The60FPS stress goal remains unmet and disclosed; typical lower-population play is not inferred to meet a particular FPS without measurement.

[OPEN_QUESTIONS.md](OPEN_QUESTIONS.md) records artistic direction, final licensing, localization/audio, balancing, buff/shield expiry defaults and Web/GitHub limitations. [MANUAL_QA.md](MANUAL_QA.md) is ready for owner review. Geometric articulated characters are original placeholders; final pixel art is not claimed. Normal enemy variety is currently the chaser framework plus the two bosses/auxiliary chasers. Human manual acceptance, a20-minute soak, public signing, Web parity and final tuning are not claimed by this engineering delivery.

Distribution: `builds/EndlessSurvival-Windows.zip` (extract and launch `windows/Play.cmd`), and reproducible source archive `builds/EndlessSurvival-Source.zip`. Windows package is private/unsigned and includes the full official runtime because matching stripped templates are unavailable. Source license is reserved, not silently set to MIT. Git metadata/authentication restrictions remain; no commit/push claimed.

Task ledger closure: M3-01..05, M4-01..07 and M5-01..06 checked only after the evidence above passed. M4 dodge verification uses real WASD input on PlayerActor in the native renderer; it does not assert a human operated the keyboard. M5 profiling means measurement/cleanup completed, not that the60FPS target passed. M5 Web task is the required attempt with a documented template blocker, not a successful Web release. Manual human acceptance remains an owner-review item rather than a fabricated test result.

Final source archive inspection: includes project.godot and the full endless regression; excludes Git/internal config/userdata and engine executables. Source ZIP is rebuilt after ledger/document closure so it contains these final records. Final binary package/extracted smoke use content stamp endless-demo-v1; changing that stamp did not alter numeric definitions or RNG behavior.

## BUG-01 - Enemy navigation stalls (2026-10-15)
User report: enemies bunch together and hit apparently empty space rather than approach the player.
Scope: M1-02 / M4-01 / M5-04 regression; no gameplay, spawn-radius, capability or LOCKED contract changes.
Files: scripts/world/arena_geometry.gd, scripts/actors/enemy_actor.gd, tests/integration/test_enemy_navigation.gd, tests/run_all.gd, docs/04_TASKS.md, this log; Windows release rebuilt.
Cause: world-to-grid conversion used cell centers as origins and truncation, shifting cell boundaries by half a cell. Cached steering for 0.2s also overshot turns. Routes could steer through obstacle corners; solid goal cells fell back to chasing through the obstacle.
Fix: floor relative to grid origin, current-position steering every physics tick over the shared cached flow, swept segment clearance for direct approach and corner alignment, nearest open routing for wall-adjacent goals. No actor-name branching or additional physics obstacles introduced.
Environment: Windows, local Godot 4.7.2.stable.official.ed1daf0bf. APPDATA set process-locally to .local-data after initial baseline launch reported unavailable user://logs.
Baseline reproduction: five actual EnemyActor CharacterBody2D instances chasing a stationary actual PlayerActor around the authored obstacles for 900 physics frames. Two failed to reach the player (positions -847.17,-12.83 and -188.95,-9.58); three reached. This baseline was observed in command output, not saved as a separate evidence file.
Focused final verification: tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/integration/test_enemy_navigation.gd => six checks, zero failures, exit 0. Includes five approach angles and an additional 600-frame chase with player at (285,0), next to an obstacle. Evidence: docs/evidence/navigation-fix.log.
Import: same executable --headless --path . --editor --quit => exit 0, no error/warning diagnostics (navigation-import.log). Full regression and package evidence: navigation-regression.log and navigation-package.log.
Package: tools/package.ps1 => exit 0; exported Windows PCK, rebuilt ZIP, standalone release smoke marker RELEASE_SMOKE_OK profiles=3 boss_victories=3.
Limitations: this confirms deterministic physics scenarios, not visual matching of the attached screenshot or a human acceptance playtest. Enemies intentionally have collision mask 4 (world only), so overlapping enemy sprites can still occur near a shared target; no evidence of duplicate instance creation was found. Stable 60FPS stress performance remains unclaimed. Next: user replay of the reported location and separate crowd-spacing work if visual overlap remains undesirable.

Final regression: --headless --path . --script tests/run_all.gd => RESULT suites=26 failures=0, exit 0. The full run used the initial five-case navigation fixture; after the wall-adjacent-goal follow-up, the final focused six-case suite passed separately. No diagnostic errors/warnings in either final evidence log. BUG-01 checked complete for navigation stall repair; crowd sprite overlap remains the limitation above.

## UI-01 - PLAY / CHARACTER / SETTING menu (2026-10-15)
User request: split entry menu into PLAY, CHARACTER and SETTING.
Implementation intent: presentation-only change under M3-04 / M5-01; keep combat, skill/augment contracts and settings schema intact. Touch foundation_menu.gd and boot scene tests; verify page visibility, explicit selection, settings saves/rebinding and actual selected-loadout scene launch.
Implemented: HOME shows PLAY/CHARACTER/SETTING and Quit; Astra is the initial selection. CHARACTER presents three authored placeholder portraits, base HP/armor/speed/crit, basic and four skill names, unlock levels/rank caps/base cooldowns, and SELECT controls. Selection does not start combat. PLAY launches the chosen loadout with configured seed. SETTING holds Auto/Manual, rebinding, seed and fullscreen/window controls. BACK cancels pending rebinding and returns home. Scroll container supports character details without cropping controls.
Files: scripts/ui/foundation_menu.gd, tests/scenes/test_boot.gd, docs/04_TASKS.md, README.md, WORK_LOG.md; rebuilt release/source artifacts.
Environment: Windows / Godot4.7.2; graphical verification used OpenGL Compatibility on NVIDIA RTX3050 Laptop GPU.
Executed graphical boot/navigation test: --path . --script tests/scenes/test_boot.gd -- --capture-frame => exit0 / failures=0, no errors/warnings. Test uses isolated settings, verifies default page, CHARACTER and SETTING visibility, Vex selection, duplicate-key rejection, Esc cancellation, U rebind/save, invalid seed rejection, and actual PLAY creating a Vex CombatRunRoot. Visually inspected menu-home.png, menu-character.png and menu-setting.png: all three portraits, skill metadata and select buttons readable at1152x720. No human manual QA claim.
Initial Python transformation attempt was NOT EXECUTED because python resolved to inaccessible WindowsApps alias; changes were then applied through patches. No feature-success claim relies on that failed command.
Limitations: portraits remain geometric placeholders pending supplied sprite sheets; selection lasts for this menu session and is not added to persistent settings. Existing in-run pause settings remain available. No gameplay or LOCKED changes.

Final UI-01 verification: editor import exit0; headless boot/selected-loadout launch exit0; settings32 checks failures0 with separate-process persistence; graphical navigation test exit0; tools/package.ps1 exit0 and standalone RELEASE_SMOKE_OK profiles=3 boss_victories=3. Evidence: menu-import.log, menu-boot.log, menu-settings.log, menu-graphical.log, menu-package.log. UI-01 complete. Next: integrate supplied sprite sheets after asset/frame review.

## AIM-01 - Ranged basic trajectory and Manual facing indicator (2026-10-15)
User requested: fix curved/missed Mage/ADC shots; display a curved arrow around the player indicating facing, and use this direction for Manual skills.
Scope: projectile aiming/steering and presentation/input; no character branching in shared mechanics, no change to damage/rank/cooldown/budgets/save schema. User explicitly authorizes this aiming behavior change. Existing PC mouse aim default retained.
Files: scripts/combat/{combat_service,projectile,targeting_service,skill_controller}.gd, scripts/data/basic_attack_executor_definition.gd, scripts/actors/player_actor.gd, scripts/core/combat_run_root.gd, tests/integration/test_aiming.gd, tests/run_all.gd, backlog and this log; Windows/source archives rebuilt.
Cause found: executor_steering implicitly returned1.0 for every BasicAttackExecutorDefinition, causing basic shots to curve even without Homing. Homing reacquisition also selected relative to the shooter and could choose an already-pierced target repeatedly.
Fix: base projectile steering defaults to zero; explicit Homing modifier still applies. Ranged basics compute constant-velocity interception at launch and then fly straight. Homing reacquires relative to projectile position within remaining travel range and excludes previously-hit actors; faction/live actor filtering preserved.
Manual: mouse direction defines PlayerActor.facing independently of WASD; auto basic attacks cannot overwrite Manual facing. A cyan curved arc plus arrowhead displays facing only in Manual. Manual cast and indicator share facing; cursor exactly on feet preserves prior facing. Ground-target skills retain cursor distance along facing; self shields/buffs/areas remain centered on the caster. Basic attacks remain automatically targeted per LOCKED requirement. Homing, Split and Multishot may intentionally bend/spread projectiles after launch.
Executed initial graphical test: local Godot4.7.2, Compatibility/OpenGL, RTX3050 Laptop GPU; --path . --script tests/integration/test_aiming.gd =>13 checks failures0. Actual physics verifies both Astra and Vex basics hit a laterally moving target with unchanged direction, Manual casting upward while enemy is to the right, and zero-offset facing preservation. Inspected docs/evidence/manual-facing.png: curved cyan indicator and tip visible around actor. Screenshot is a controlled fixture, not a visual match claim for inaccessible attachment.
Expanded focused suite adds actual Homing reacquisition excluding a pierced target and turning toward a fresh target. See aim-focused-final.log. Regression: --headless --path . --script tests/run_all.gd => aim-regression.log. Import evidence aim-import.log. Packaging tools/package.ps1 => aim-package.log.
Known limitations: constant-velocity prediction cannot guarantee hits after sudden enemy direction changes; walls can block shots. No guaranteed-hit or wall-penetration mechanic added. Curved arrow is a procedural approximation; exact attachment appearance has not been inspected. No human manual QA or stable stress60FPS claim.

Final AIM-01 results: full regression RESULT suites=27 failures=0, exit0; it ran the original13-check aiming fixture. Expanded final aiming fixture15 checks failures0 separately, including new Homing reacquisition. Graphical aiming fixture13 checks failures0, image inspected. Import clean; package exit0 with RELEASE_SMOKE_OK profiles=3 boss_victories=3. No ERROR/WARNING/FAIL diagnostics in final regression/focused/package logs. AIM-01 complete; next user acceptance of aiming feel and supplied sprite integration.

## ART-01 - User supplied Vex sprite atlas (2026-10-15)
User explicitly requested inspecting and using assets/sprites/characters/vex/vex if usable. Inspected original PNG:512x512 transparent sprite atlas,64x64 cells; Aseprite header reports one512x512 frame, with no animation tags found. Mapping is inferred from rows rather than asserted author metadata.
Presentation-only mapping: optional SpriteFrames on CombatLoadoutDefinition, supplied to PlayerActor in run and CHARACTER preview. Generic ActorSprite consumes movement, facing, attack feedback, dash and health; no character-name checks in shared combat/augment code. Existing profiles without visual_frames keep JointedCharacter. This additive visual configuration does not change LOCKED combat, capability or save contracts.
New files: scripts/ui/actor_sprite.gd, content/characters/vex_visual_frames.tres, tools/import_vex_sprites.gd, tests/integration/test_sprite_visual.gd. Modified: player_actor.gd, combat_run_root.gd, foundation_menu.gd, combat_loadout_definition.gd, vex_loadout.tres, tests/run_all.gd and tests/scenes/test_boot.gd. Original PNG/aseprite/projectile files preserved without image edits.
Frame map (zero-based rows): run row0/8 frames, death row1/8, dash row2/7, attack row3/7, idle row4/6, cast row5/4. Remaining rows and projectile.png are not assigned. Nearest filtering; horizontal mirroring supports left/right. Source art is a bow character; this is a cosmetic skin over the existing Vex kit, not a gameplay/class rewrite. Eight directional artwork is not present.
Verification: Godot4.7.2, Windows, OpenGL Compatibility/RTX3050. Editor import clean (vex-sprite-final-import.log). Sprite generation tools/import_vex_sprites.gd saved Resource with error0. Actual graphical test tests/integration/test_sprite_visual.gd initially found death transition delayed; fixed by listening to health.depleted. Final49 checks failures0:40 nonempty64px frame regions plus profile/driver/idle/run/attack/cast/dash/mirror/death. Full evidence vex-sprite-test.log. Graphical boot/menu test selected Vex, launched its actual run and captured menu-character.png and vex-in-game.png; images inspected. No human manual play claim.
Full regression evidence: vex-sprite-regression.log. Windows packaging evidence: vex-sprite-package.log; standalone RELEASE_SMOKE_OK profiles=3 boss_victories=3. Build/source refreshed.
Limitations: row labels are inferred and may be retuned if author provides metadata. Sheet does not supply eight independent directions, nor independent animation variants for every Vex skill. Existing active skills share cast presentation and retain generic gameplay VFX/projectiles. Original source/license not supplied; asset provenance recorded in ASSET_LICENSES.md without claiming an open license.

Final ART-01:28 regression suites failures0 exit0. Subsequent presentation-only correction stores idle's native left orientation as SpriteFrames metadata; generic driver mirrors based on each animation orientation. Updated focused graphical49 checks failures0 and graphical menu/actual-Vex-run launch passed after that correction; inspected updated in-game capture. Final package smoke passed profiles3/boss_victories3. Package rebuilt after orientation correction. Existing baseline49 checks remain49; no manual human QA asserted. ART-01 complete.

## ART-02 - Boros sprites and common character size (2026-10-15)
User requests Boros sprite integration, slightly larger characters and consistent visible size. The user replaced the initially observed Fullmain.png during this task; implementation uses the subsequently supplied assets/sprites/characters/boros/boros_sprite_pack with96 strips and metadata.
Scope: presentation only. No hitbox, movement speed, target range, damage, skill unlock/rank, capability or settings changes. All baseline character visuals use72px reference opaque height and foot line20px below actor origin. Sprite scale is derived from its reference idle alpha bounds; Astra geometry uses its57px authored height. Existing transform enlargement1.25x remains and restores the baseline on expiry. Menu portrait region expanded to165px to fit the larger artwork.
Files: new tools/import_boros_sprites.gd, content/characters/boros_visual_frames.tres, tests/integration/test_boros_visual.gd; updated ActorSprite, PlayerActor, JointedCharacter, run/menu wiring, Boros loadout, tests/run_all.gd, backlog and logs.
Generic ActorSprite supports optional eight-direction metadata, preserves frame progress on facing changes, and retains Vex's per-animation left/right mirroring. Boros uses metadata-provided strips/FPS/loop flags; aliases attack=basic_attack, dash=charge_loop, cast=ground_slam. Data maps area skill to ground_slam, shield to iron_resolve, buff to transform_start. Gameplay timing remains authoritative; provisional impact-frame numbers do not add delays to gameplay. Native charge start/end, hurt and transform-end are imported and available, but current run events use the common dash/cast presentation flow rather than chaining every optional transition.
Asset checks found4 entirely transparent frame slots across hurt_south (3), hurt_north (0,3), hurt_east (0), zero-based. Importer now holds the preceding valid pose (or first following valid pose when needed); original PNGs remain unchanged. Entirely empty strips fail import. Evidence boros-authoring.log records these repairs. Source README explicitly calls the art a visual prototype with reused poses; smoothness/perfect anchors are not claimed.
Verification environment: Godot4.7.2 Windows/OpenGL Compatibility RTX3050. Final editor import clean (boros-final-import.log). Initial focused141-check test exposed3 affected animation strips; after repairing the four empty slots the same actual graphical test reports141 checks failures0. It validates all120 native/alias directional animations, real eight-direction selection, skill actions, dash/death, transform growth/restoration, equal72px baseline and unchanged14px body collider. Early test-only raw Image.load_from_file warnings were eliminated by reading imported Texture2D images; product code never used raw loading.
Vex graphical regression49 checks failures0 with the generalized driver. Menu boot/selected-loadout launch passed and updated menu-character.png inspected. character-sizes.png inspected side-by-side for all three characters. Full suite evidence boros-regression.log; it began before the empty-frame repair and may retain the original focused failure. Final repaired focused result is boros-visual-test.log. Final standalone package evidence boros-package-final.log.
Limitations: supplied artwork/prototype reused poses and alignment imperfections remain; all frames use reference-size normalization, not per-frame rescaling that would cause pulsing. Vex still uses mirrored two-direction art; Astra remains procedural. Boros supplied greatsword is cosmetic over the unchanged melee kit. Original asset provenance/license not independently verified, no permissive license claimed. No human manual QA or stable stress60FPS claim.

Final ART-02 verification: full regression finished29 suites with1 failed suite (the pre-repair Boros frame-validity fixture,3 affected strips). The other28 suites passed without errors/warnings. Reran the failing fixture after the source-frame repair:141 checks failures0, exit0, no diagnostics. Vex graphical49 checks failures0. Final package rebuilt from repaired SpriteFrames: tools/package.ps1 exit0, RELEASE_SMOKE_OK profiles=3 boss_victories=3, no error/warning diagnostics. Thus the failed fixture is resolved by the recorded focused rerun; no claim of a second full29-suite run. ART-02 complete. Next: user visual acceptance and future replacement of provisional Boros poses.

## UI-02 - Movement-facing aim, atlas clipping and Vietnamese (2026-10-16)
User explicitly corrects Manual aiming to the most recent movement/facing rather than mouse, reports a repeated Boros strip to the right while running, and requests Vietnamese.
Changes: PlayerActor updates facing from nonzero WASD and preserves it at rest. Manual SkillController uses that facing and rank range, ignoring cursor overrides for player characters. Keyboard and HUD skill commands pass the same facing-based intent; basic auto targeting stays unchanged. Self skills remain self-centered. This supersedes the earlier mouse default per explicit user direction.
Boros/Vex AtlasTexture frames now use filter_clip=true so sampling/drawing stays inside each cell. All sprite metadata, source PNGs, animation counts,72px baseline, hitboxes and gameplay values preserved. Viewed a running Boros renderer fixture: one actor image, no repeated strip beside it; original prototype's small baked stray pixels/pose inconsistency are not a claim of production-quality art.
Vietnamese: Godot CSV en/vi catalogs, Vietnamese default locale, translated menu/character stats and skills/settings/HUD/status/pause/death/upgrade cards/notices. UiLocalizer translates copies of upgrade labels; definitions, stable IDs and canonical mechanic test strings remain unchanged. English catalog retained; this iteration does not add a language selector or change settings schema.
Files: player_actor.gd, skill_controller.gd, combat_run_root.gd; import_boros_sprites.gd/import_vex_sprites.gd and generated SpriteFrames; UI scripts and new ui_localizer.gd; content/localization/phrases.txt/ui.csv/imported catalogs; project.godot; aiming/Boros/localization tests and runner; README/package docs.
Verification environment: Godot4.7.2 Windows/OpenGL Compatibility RTX3050. Focused movement-aim16 checks failures0, including actual WASD down, release/hold, and Manual cast passed an opposite upward cursor point still firing down (movement-aim-test.log). Clipped directional frame/renderer suite141 checks failures0 (boros-clip-test.log). Localization8 checks failures0 including Vietnamese diacritics, formatted HUD/upgrade, English fallback and immutable stable IDs (vi-localization-test.log). Graphical boot selected Vex and launched run successfully; graphical release presentation passed. Inspected menu-character.png, m5-upgrade.png, m5-pause.png and running character-sizes.png. Final import clean (vi-import.log).
Implementation issue: an initial broad regex translation transformation corrupted string boundaries and produced parse/color errors. It was discarded; four affected scripts restored from the prior source archive, current movement-facing changes reapplied, and translations applied only to exact known message templates. Final import/render tests above passed. No success claim relies on the failed transform.
Full regression: vi-regression.log. Packaged standalone verification: vi-package-final.log. No human manual-play or stable60FPS claim; art remains the supplied prototype. Next: user replay of the reported Boros movement case.

Final UI-02 results: full regression29 suites failures0 exit0, no error/warning diagnostics (vi-regression.log); newly added localization suite8 checks failures0 independently (vi-localization-test.log). Aiming16 checks includes actual movement/rest and opposite cursor rejection; Boros clipping/size/directional141 checks passed within full regression. Graphical boot and release presentation each passed. Final Windows package tools/package.ps1 exit0 with RELEASE_SMOKE_OK profiles=3 boss_victories=3 (vi-package-final.log). Runtime code unchanged after these checks; package README corrected to movement-facing aim. UI-02 complete.

## ART-03 - Baked neighbouring-pose fragments (2026-10-16)
Follow-up user report says the Boros duplicate-fragment issue persists; two attached reference images supplied. Library resolved their exact IDs but local image retrieval failed because the helper could not reach its service (DNS). Therefore attachment visual inspection was NOT performed; diagnosis below is independently grounded in the actual local PNGs, not a claim to have seen the attachments.
Reproduction: generated an internal contact sheet of every128px frame across all eight run strips. Many cells visibly contain disconnected cape/sword fragments from adjacent poses. These pixels lie INSIDE each source cell, so AtlasTexture.filter_clip cannot remove them. The prior statement that clipping alone fixed the reported issue was too broad.
Fix: tools/clean_boros_sprites.py creates96 derived strips under assets/sprites/characters/boros/cleaned. It retains the largest8-connected alpha component in each cell and preserves its original alpha/pixels; removes disconnected fragments. Original supplied pack untouched. Blank source cells stay blank and the existing Godot importer still holds valid neighbouring poses for four empty hurt slots. Importer now references derived strips, keeping frame counts, metadata, filter clipping and gameplay intact. Cleanup result:844 affected frames,149599 removed pixels across96 strips. Full per-frame report: docs/evidence/boros-fragment-cleanup.json.
Files: tools/clean_boros_sprites.py, tools/import_boros_sprites.gd, generated derived PNGs and boros_visual_frames.tres; tests/unit/test_sprite_cleanup.py, backlog/log/license notes. Combat/input/translation code unchanged.
Verification: local Godot4.7.2 Windows/OpenGL RTX3050; editor import and generator succeeded. Actual graphical Boros suite141 checks failures0: all directional frames nonempty, eight directions/actions,72px baseline and unchanged14px collider. Evidence boros-fragment-visual.log. Inspected before/after contact sheets and running renderer fixture: disconnected cape/sword fragments removed, main connected body/weapon/cape retained. Original prototype pose timing and clipped source weapon extents cannot be reconstructed by this cleanup.
Python regression: tests/unit/test_sprite_cleanup.py checks a main body/connected weapon/soft alpha with two neighbouring fragments, transparent/idempotent cases, and every frame in all96 actual derived strips. Evidence boros-fragment-tests.log. Standalone package evidence boros-fragment-package.log. No new full gameplay regression claimed for this asset/import-only correction; prior gameplay coverage retained.
Limitations: any disconnected intentional accessory/particle in this prototype is also removed; connected source artwork and existing source cropping remain. Exact attachment-to-render match remains unverified due to retrieval failure. Next: user replay of the reported movement frame in the new build.

Final ART-03 results: Python regression3 tests OK in57.109s, covering all96 actual strips plus fixtures; graphical Boros141 checks failures0; importer and editor clean. Windows package exit0, standalone RELEASE_SMOKE_OK profiles=3 boss_victories=3, no error/warning diagnostics. Final package uses the regenerated cleaned SpriteFrames. ART-03 complete for independently reproduced source-fragment defect; user acceptance of the reported movement case remains pending.

## A0–A8 Art handoff implementation — 2026-10-16
Authorization: user requests autonomous production from assets/vfx/Endless_Survival_Art_Agent_Handoff_v1, A0–A1 first, then sequential milestones until a playable graphics demo. Read handoff README/order, prior architecture/gameplay/decision/agent snapshots, all eight art specifications, schemas/examples and tooling references. Latest docs decisions retain movement-facing Manual input and72px presentation; no locked gameplay change.
Selected tasks sequentially: A0 inventory → A1 pipeline → A2 actors → A3 Astra → A4 Vex → A5 Boros → A6 maps → A7 integration → A8 delivery/performance. Acceptance/backlog: docs/ART_TASKS.md; root schedule cross-reference below. A0–A7 technical prototype implementation complete. A8 package/evidence delivered, stable60FPS gate OPEN. Subjective visual acceptance PENDING throughout.
Files/systems: tools/art_pipeline (audit, deterministic body/weapon/terrain/VFX sources, strict schema/PNG validators, tests, importer, captures, stress and review report); assets/characters/{astra,vex,boros} (636 separate RGBA frames, manifests/weapons/SpriteFrames); assets/tiles and assets/vfx/generated (3 themes/15 manifests); shared CharacterVisual scene, VisualController/VisualProfile, ActorSprite compatibility and optional art_frames projection; presentation-only CombatVisualFactory/Effect and confirmed visual event adapters. No changes to skill stats/unlocks/capabilities, damage/modifier ordering, seeded RNG, input defaults or collider dimensions. Existing collision/navigation generator remains authoritative; TileMapLayer has no physics. Renderer caches immutable projectile draw commands; damage and swept movement unchanged.
Scope boundaries: new visual signal is not a gameplay proc/event budget path; its listeners allocate only bounded cosmetics outside CombatService's direct projectile children. Resource profile data read-only. Legacy sprite resources remain test fixtures and supplied originals, removed from active loadouts and excluded from runtime export. No concept pixels used in assets. Original241 asset files retain baseline hashes. Art remains original procedural prototype; no claim of reference-quality polish.
Tests/environment: Godot4.7.2 stable Windows Compatibility/OpenGL3.3 RTX3050 Laptop / Ryzen5 6600H; Python3.12.14/Pillow12.3.0. See docs/ART_ACCEPTANCE.md for commands/logs: pipeline6 unittest cases pass; importer108 clips; character228 checks; VFX41 checks including actual split compatible/negative cases; map3300 checks across300 seeds; full gameplay33 suites failures0 and no ERROR/WARNING diagnostics. Final presentation-only weapon/pause/draw-cache changes separately rerun focused suites, renderer and packed smoke. Renderer48 captures plus3 GIFs; standalone release smoke3 profiles/3 boss victories. All original asset hashes preserved.
Errors were retained and corrected, not labeled successes: initial generator rectangle exception, temp-directory permissions, class-cache-dependent interrupted regression, preview HUD overlap/legacy VFX overlays, pause test synchronization and invalid stress fixture. Details: ART_ISSUES.md and baseline logs.
Measured final stress (60 rendered frames,300 actual projectiles):100 enemies median16.256ms/p9523.555ms;200 median19.947/p9534.972;400 median64.093/p9593.246; functional failures0, cosmetic trails<=120/impacts<=80.100/300 median improved from32.836ms by caching static draw commands; stable60FPS remains unmet at p95. Production cap110 unchanged. Do not check A8 complete for this result.
Delivery/review: builds/EndlessSurvival-Windows.zip and builds/windows/Play.cmd; CHARACTER → Xem đồ họa / Art preview runs real executors. screenshots/art/index.html includes contacts, actual skill captures, GIFs and seeds1/42/999 map images. Owner only needs to test/review. Optional Web export NOT EXECUTED; no compatible local Web template asserted. Git main has no commits and .git is read-only in this environment; no commit made. Next: performance profiling/polish for A8 and owner visual approval.
