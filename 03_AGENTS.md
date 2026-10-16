# 03 — AGENTS.md (Repository Operating Rules)
**Applies to all coding AI agents, sub-agents, reviewers, and humans contributing to this Godot project.**

## 0. Mandatory startup ritual
1. Read, in this order: `05_DECISIONS.md` → `01_CORE_ARCHITECTURE.md` → `02_GAMEPLAY_SPEC.md` → `04_TASKS.md` → this file.
2. Inspect repository tree and current commit/status, detect installed Godot version (`godot --version` or binary equivalent); no assumption that project already exists.
3. Select exactly one unchecked task from `04_TASKS.md` whose dependencies are satisfied. Identify files touched and test coverage prior to editing.
4. Show concise implementation intent: requirement IDs, system boundaries, uncertainty, verification plan. If running unattended, write plan to `docs/WORK_LOG.md` instead of asking noncritical clarifications.
5. Do not fabricate successful builds/tests. Run available verification after any feature. Record tested environment, commands, errors and outputs.

## 1. Authority and conflict resolution
Priority: (1) latest explicit user instruction (2) `05_DECISIONS.md` LOCKED entries (3) `01_CORE_ARCHITECTURE.md` invariant contracts (4) `02_GAMEPLAY_SPEC.md` mechanics (5) `04_TASKS.md` schedule (6) implementation convenience. If two documents conflict, stop changes affecting that conflict and record it under `Unresolved / Needs approval`, implement independent tasks in the meantime. For ambiguous numbers marked DEMO DEFAULT, select documented default and continue. Never silently turn DEMO DEFAULT into LOCKED.

## 2. Change-control policy
- Architectural change (public interfaces, data ownership, modifier ordering, capability semantics, event budget, save schema) requires ADR in `docs/adr/ADR-YYYY-NNN.md` and explicit user approval **before changing locked design**.
- Gameplay change (boss spawn schedule, skill unlock levels, 3-choice upgrade, passive ranks, class identity, input default) requires approval.
- Implementation detail (utility helper, scene nesting, import naming) may change without approval if contracts, behavior and tests preserved. Note mapping in WORK_LOG.
- Balancing numbers marked DEMO DEFAULT can be adjusted after measurements; write test evidence and a `BALANCE_LOG.md` entry. Never adjust to mask functional bug.
- For blocked decisions: isolate behind config/strategy interface, add TODO with document reference, continue unrelated tasks. No invented user preferences.

## 3. Development conventions
- Godot 4.x stable, GDScript 2.0; use statically typed declarations for public methods, signals and collections whenever sensible.
- PascalCase `class_name`, snake_case file names, event names in past tense (`damage_applied`), internal methods `_prefix`, `StringName` IDs for registered content.
- Scene/script/resource separated; `Resource` content definitions are read-only at runtime; user run state owned by runtime objects.
- Composition over subclass explosion. Shared mechanics implemented once; subclass only where actual behavior differs and can be justified.
- Dependency direction: content definitions → generic interfaces; runtime subsystems depend on interfaces and data; game UI depends on gameplay events; no circular singletons.
- No broad `get_tree().get_nodes_in_group()` for every projectile per frame once spatial indexing is available; use area or spatial queries and validated faction filters.
- Never silently `pass` a function to claim completion; failing feature is explicitly TODO and task remains unchecked.
- No paid/proprietary assets and no external intellectual property. Placeholder images/audio authored locally, permissively licensed or generated; record attribution/license in `ASSET_LICENSES.md`.
- No network dependency in runtime demo. All assets local, no telemetry unless opt-in. Build/export steps reproducible.

## 4. Required content authoring checklist
**New skill:** global stable ID; owned slot; unlock level; max rank; four/three rank definitions; tags vs executor-verified capabilities; targeting mode; cooldown; area/projectile geometry; status policy; effect VFX placeholder; unit test.
**New augment:** stable ID; eligibility requirements; max rank; all numeric rank values; base/derived trigger type; scope and bind-target behavior; stacking and exclusions; proc recursion policy; presentation tooltip; 2 compatible-case tests and 1 incompatible-case test.
**New character:** class, base stats, basic, 4 active skills with rank tables; data validation; controller compatibility; keybinding and auto/manual smoke tests; screenshot/video if available.
**New boss/map:** data-driven thresholds/attack patterns or template geometry; safe spawn, warning telegraph, pathfinding check, lifecycle tests and profiling.

## 5. Required tests and evidence
Before checking task `[x]`, supply: files changed, Godot parsing/headless run result, automated tests and results, manual acceptance steps if GUI required, known limitations, next task. Recommended command patterns (adapt binary):
```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/run_all.gd
# manual Windows launch through Godot project manager or executable
```
Never report code passes because it looks syntactically valid. If Godot missing, write NOT EXECUTED and task remains partially complete; do not assert playability. Fail build on invalid content/capability or missing IDs rather than silently degrading to no-op.

## 6. Test matrix for reusable mechanics
| Mechanic | Compatible case A | Compatible case B | Negative case | Extra regression |
|---|---|---|---|---|
| Split | Astra J | Vex L | Boros J | no double split secondary |
| Pierce | Astra J | Vex L | Boros K | one target hit per projectile |
| Multishot | Vex J | Astra basic | Astra K | projectile cap |
| Echo | Astra J | Boros J | K self shield if executor opts out | no echo-of-echo |
| Area expand | Astra L | Boros J | Vex K | collision radius matches VFX |
| Shield reflect | Astra K | Boros K | Vex L | no reflect-on-reflect |
| Dash shockwave | Vex K | Boros L | Astra J | one completion proc |
| Explode on hit | Astra J | Vex L | Astra K | only once per root/target |

When a capability is absent from a proposed sample, adapt test to real two compatible skills by adding a test fixture skill executor, not fake it via tags.

## 7. Explicit anti-patterns
**PROHIBITED**: `if skill.owner.name == 'Astra'` in shared augment engine; shared Resource mutation; 1-off copied split projectile logic; resource/content IDs based on localized display label; signal chain with unbounded recursion; RNG from global functions inside seeded system; lowering spawn safe radius to make tests pass; bypassing offer eligibility; stubbing fake success; changing story scope or making game online/multiplayer without request.

## 8. Agent instruction hierarchy in practice
For every milestone:
1. Read task IDs and definitions.
2. Implement minimal vertical slice satisfying contracts.
3. Write focused tests, then integration tests.
4. Run checks and inspect runtime evidence.
5. Update `04_TASKS.md` checkboxes with evidence links in `WORK_LOG.md`.
6. Update `05_DECISIONS.md` only for confirmed decisions, not assumptions.
7. Commit logical change with message e.g. `feat(augment): implement generic projectile split` when repository uses git.
8. Report one paragraph summary plus outstanding blockers.

## 9. PR review / quality gate
Reject if: no deterministic test; forbidden character branching; repeated effect implementation across skills; undocumented compatibility; missing numeric rank config; regressions to 3-option selection; unsafe spawn; boss repeats at same threshold; game cannot launch due to parse errors; reference assets with unclear rights; performance damage without budget.

## 10. Handling missing assets or tools
Build gameplay with colored geometric placeholders and generic particles. No asset search needed to validate architecture. If a component cannot be tested due to no Godot installation, prepare files and tests but mark integration incomplete; do not represent generated archive as runnable proven demo. User can later run project, or agent can install/configure engine with authorization per environment.

## 11. Milestone-specific done criteria
Use `04_TASKS.md` as canonical backlog, never replace checkbox progress with narrative status. **Definition of Done** requires implementation + test + no high-severity open bugs + reproducible launch instructions. Unit tests that only check mocked stubs are not enough for scene gameplay milestones.

## 12. Recommended first task
M0-01: project skeleton + headless loader + content registry with validation + test runner, then M0-02 Resources. Do not start with polished visual art or three characters at once.
