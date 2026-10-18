# VIRIDIAN — Control Mage | M.U.G.E.N → Godot handoff v1.0

**Objective:** Add original game character Viridian to the existing Endless Survival Godot 4 project, prioritizing legitimate reuse of visual/audio material from the user-supplied Dr. Doom M.U.G.E.N archive as a **private technical proof of concept**. Existing Astra/Vex/Boros gameplay and Universal Augment rules remain authoritative. Viridian is **the fourth character**, not a replacement; multiplayer remains deferred until the main trio's VFX are finished.

## Reading order
1. `01_SOURCE_AUDIT_AND_MAPPING.md` — provenance, evidence, mapping candidates
2. `02_CHARACTER_GAMEPLAY_SPEC.md` — all behavior/numerics and skill ranks
3. `03_ART_ANIMATION_VFX_SFX.md` — art direction, timelines, fallback visuals
4. `04_GODOT_ARCHITECTURE.md` — code and data contracts
5. `05_AUGMENTS_AND_BALANCE.md` — modifiers, conflicts, tests
6. `06_AGENT_TASKS_AND_QA.md` — milestones, acceptance, reporting
7. `07_AGENT_INSTRUCTIONS.md` — copy into working instructions
8. `SOURCE_STATE_INVENTORY.csv`, `SOURCE_MANIFEST.json` — automatically derived source metadata

## Hierarchy / conflict policy
Existing `CORE_ARCHITECTURE`, `GAMEPLAY_SPEC`, `DECISIONS`, current repository code > this Viridian proposal for shared engine rules. This document controls only Viridian-specific additions. Do not change existing class, skills or character VFX. Any disagreement: log and request approval before destructive changes.

## Status legend
`CONFIRMED_SOURCE_TEXT`: IDs/names verified in plain-text CNS or DEF. `CANDIDATE`: expected correspondence, not yet established from decoded sprite/audio. `DEMO_DEFAULT`: suggested gameplay number, tuned through tests. `LOCKED_USER`: user's explicit choice.

## Rights
Source files include third-party IP and community modifications. A private 4-player game is not an automatic license to redistribute. Keep imported third-party assets isolated, retain attribution/provenance, do not publish them or embed them in publicly downloadable game builds without clearance. Use independently created fallbacks if permission is uncertain.
