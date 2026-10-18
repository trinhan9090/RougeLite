# ENDLESS SURVIVAL — WIZARD OF LEGEND–INSPIRED VISUAL PRODUCTION CONTRACT v3.0

**Status:** IMPLEMENTATION SPEC for visual systems only. **Audience:** AI coding/art agent using Godot 4/GDScript. **Primary style:** original, readable action pixel art inspired by the *production principles* of Wizard of Legend (compact top-down characters; fast anticipation/impact/recovery; high-contrast, layered spell VFX; restrained environment). **Do not copy game sprites, maps, UI, names, audio, proprietary palette files or effects.**

## Canonical decisions and precedence
1. `governance/01_CORE_ARCHITECTURE.md`, `governance/02_GAMEPLAY_SPEC.md`, `governance/03_AGENTS.md`, `governance/05_DECISIONS.md` govern LOCKED mechanics. Visual work may not change class, attack/skill behavior, costs, unlocks or augment compatibility. Follow source repository's latest explicitly approved changes if conflicts are documented.
2. This v3 package replaces the **visual pipeline** in v2, not the game architecture. v2 may be kept for reference only; **3D is no longer required for character art**. Blender remains OPTIONAL for props, complex assets or source geometry when rendering produces better sprite results.
3. This package describes a user-review-only workflow: Agent creates, sources, scripts, validates, imports, runs, captures and iterates. Human provides visual approval at gates. Automation does not guarantee art quality.
4. Work order: read these 8 docs (01–08), then the original source governance, then inspect live Godot repository, then execute A0 onward. Do not silently overwrite a working asset, scene or branch.

## Key visual decisions — defaults, not immutable gameplay
- 2D top-down 3/4; logical viewport **640×360** at integer window multiples, avoid fractional zoom for pixel sprites. Profile actual camera and UI at 1× and 2×.
- Character *opaque body height* target **32–48 px** at baseline; use **64×64 or 96×96 transparent animation canvas** based on attack/weapon reach (large weapon effects in detached VFX). Baseline tiles **16×16** with modular 32×32 groupings. Frame/source resolutions are not identical to player height.
- Four facing directions **N/S/E/W** for A/B benchmark, optional 8 dirs only if approved after visual proof. Keep left/right variant when asymmetrical weapon/clothing warrants it. Nearest-neighbor filtering, no smooth sprite scaling.
- Pixel-art frame animation + layered weapons/secondary effects + Godot particles/shaders = primary. Blender is an optional source-art auxiliary, not the critical path.
- **Style targets:** readability and motion at native gameplay zoom, not poster illustration detail.

## Demo characters and authoritative skill ID mapping
| Character | Class | Basic | J (level 3) | K (level 6) | L (level 9) | I (level 11) |
|---|---|---|---|---|---|---|
| Astra, male mage | Mage | `light_bolt` | `radiant_snare` | `prism_guard` | `solar_field` | `celestial_beam` |
| Vex, cowboy gunslinger | ADC | `dual_shot` | `quick_barrage` | `tactical_roll` | `piercing_round` | `bullet_storm` |
| Boros, greatsword brute | Brute | `heavy_strike` | `ground_slam` | `iron_resolve` | `crushing_charge` | `titans_fury` |

**Concept posters are character identity/color/VFX references only**: they may display different spell names and moves. Never implement different moves because the poster shows them. Yuta-inspired swordsman is not among this pack's three demo characters.

## Deliverable contract
- `source/` editable art projects and procedural scripts; `generated/` transparent, frame-per-file PNGs and optional atlases; `config/` JSON schema + manifests; `godot/` reference GDScript templates; `reference/concept_art/` legacy concept posters; `governance/` old nonvisual design specs; `reports/` QA schemas/templates.
- Copy outputs into **existing live repository paths**, recording every mapping and preserving working code; no parallel game implementation.
- Evidence per gate: Godot screenshot at native zoom, video capture with all 4 directions, skill VFX with collision on-screen, dense combat, performance capture, validator report, license ledger.
- No evidence = NOT VERIFIED; no human art signoff = NOT VISUALLY APPROVED.

## File order
1. `01_VISUAL_TECHNICAL_STANDARD.md`
2. `02_CHARACTER_AND_ANIMATION_SPEC.md`
3. `03_VFX_SPEC.md`
4. `04_WORLD_AND_MAP_SPEC.md`
5. `05_AUTOMATION_CONTRACT.md`
6. `06_TASKS_QA_ACCEPTANCE.md`
7. `07_AGENT_RUNBOOK.md`
8. `08_V2_TO_V3_CHANGELOG_AND_RISKS.md`
