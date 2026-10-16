# Endless Survival — Agent handoff specification v1.0

This directory contains the canonical project specification and implementation records. The original handoff contained five Markdown documents; the workspace now also contains the Godot source project. See the root README for current launch instructions and WORK_LOG.md for executed verification. `03_AGENTS.md` is also copied to root `AGENTS.md`.

**Read order**: `05_DECISIONS.md` → `01_CORE_ARCHITECTURE.md` → `02_GAMEPLAY_SPEC.md` → `04_TASKS.md` → `03_AGENTS.md`.

| File | Purpose |
|---|---|
| 01_CORE_ARCHITECTURE.md | invariant architecture, data interfaces, modules, combat pipeline, augment compatibility, contracts, tests |
| 02_GAMEPLAY_SPEC.md | numerical and behavioral gameplay specs, 3 character kits, 20 augments/stat cores, enemies/boss/maps, edge cases |
| 03_AGENTS.md | agent permission/decision rules, coding conventions, tests, reporting and approval discipline |
| 04_TASKS.md | milestone-oriented implementation backlog, test matrix, acceptance tour, evidence template |
| 05_DECISIONS.md | verified user commitments vs provisional demo defaults, open questions and ADR policy |

**First agent request**: "Read all five documents in the specified order. Do not alter LOCKED requirements. Implement M0-01→M0-04 with actual Godot project, headless parser, content registry definitions and deterministic tests. Record outputs in WORK_LOG.md. Do not mark gameplay features complete until they run."

**Important**: Numbers not previously agreed with the user have been marked `DEMO DEFAULT` explicitly. They exist for implementation continuity, not because the user approved these balancing values. To avoid overclaiming, all tests described in these docs are *acceptance requirements*, not tests already executed.
