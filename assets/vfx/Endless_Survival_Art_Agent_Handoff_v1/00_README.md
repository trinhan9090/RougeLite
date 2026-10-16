# ENDLESS SURVIVAL — GRAPHICS / VFX AUTONOMOUS AGENT HANDOFF v1.0

**Purpose:** Give a coding AI agent enough concrete instructions to implement an end-to-end **FREE** pixel-art visual pipeline in the existing Godot 4/GDScript demo for ASTRA, VEX and BOROS. Human owner only conducts final visual review and playtesting. This document does **not** claim generated concept art is game-ready animation, or promise satisfactory results without inspection.

## Start here / strict read order
1. `reference/previous_specs/03_AGENTS.md`, `01_CORE_ARCHITECTURE.md`, `02_GAMEPLAY_SPEC.md`, `05_DECISIONS.md`.
2. `docs/01_ART_DIRECTION.md` → `02_CHARACTER_PRODUCTION.md` → `03_ANIMATION_AND_IMPORT.md` → `04_VFX_IMPLEMENTATION.md` → `05_MAP_PIPELINE.md` → `06_AUTOMATION_AND_QA.md` → `07_TASKS_AND_ACCEPTANCE.md` → `08_ASSET_LICENSES_AND_DECISIONS.md`.
3. `templates/character_manifest.schema.json` and `templates/vfx_manifest.schema.json`; example manifests and scripts.
4. Report any conflict with earlier gameplay documents before writing gameplay code. **Earlier approved gameplay supersedes concept-panel labels**. Visual-only changes must not alter mechanics or balance.

## Shipped materials
- Three user-reviewed directional concepts at `reference/concept_art/`: Astra (male celestial mage), Vex (western dual-gun marksman), Boros (dark-armored greatsword mercenary).
- Full prior architecture/gameplay/agent docs as read-only references.
- Art standards, asset layout, deterministic export/import strategy, procedural map generation, complete basic attack and J/K/L/I VFX direction, test matrix and release criteria.
- Example manifests and deterministic PNG frame validator. These are templates, not finished sprites or a finished Godot game.

## Autonomy contract
**Agent does everything practical:** research/source CC0 packs; build/normalize asset files; generate original pixel sprites using scripted shapes/artist tools or permissible sources; implement scenes/shaders/VFX; run import/tests/capture screenshots; document license provenance; refine based on technical tests. **Owner does only subjective approval and hands-on testing.** If acceptable original assets cannot be produced automatically, use clearly labeled *procedural placeholder*, never claim it is final artwork or secretly re-use copyrighted content.

## Desired output inside game repo
`art_source/`, `assets/characters/{astra,vex,boros}/`, `assets/vfx/`, `assets/tilesets/`, `scenes/visual/`, `scripts/visual/`, `tools/art_pipeline/`, `tests/art/`, `docs/ART_CHANGELOG.md`, `docs/ART_ASSET_LEDGER.csv`, `docs/ART_QA_REPORT.md`, `screenshots/art_qa/`.
