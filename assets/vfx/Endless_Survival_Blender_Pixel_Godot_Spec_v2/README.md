# ENDLESS SURVIVAL — BLENDER → PIXEL ART → GODOT PRODUCTION CONTRACT v2.0

**Audience:** autonomous coding/art AI agent working on a pre-existing Godot 4 GDScript project. **Goal:** playable vertical slice for Astra, Vex, Boros with visuals informed by three concept sheets. **User role:** visual approval and gameplay testing only; Agent does sourcing, generation, conversion, import, QA and build.

## Execution order and ownership
1. Read existing `AGENTS.md`, `01_CORE_ARCHITECTURE.md`, `02_GAMEPLAY_SPEC.md`, `05_DECISIONS.md` before touching code. Existing LOCKED gameplay wins. This package controls **art and render only**.
2. Read `01_VISUAL_TECHNICAL_STANDARD.md`, `02_CHARACTER_AND_ANIMATION_SPEC.md`, `03_VFX_SPEC.md`, `04_WORLD_AND_MAP_SPEC.md`, `05_AUTOMATION_CONTRACT.md`, `06_TASKS_QA_ACCEPTANCE.md`, `07_AGENT_RUNBOOK.md`.
3. Read `config/visual_manifest.schema.json` and sample manifest; inspect `reference/` art. Treat the concept posters as **art-direction**, not importable sprite sheets or truth about gameplay skills.
4. Produce a **baseline evidence capture** of project before editing. Work in isolated branch/worktree; do not overwrite source sprites.
5. Start with **Astra benchmark** (idle/run/basic/J/I and one polished arena), get review, then apply same pipeline to Vex and Boros.

## Precedence / discrepancy registry
- LOCKED controls: WASD; J/K/L/I remappable; Auto/Manual skills; basic auto nearest in range; unlock levels 3/6/9/11; skills rank cap 4/4/4/3; bosses every 10 levels; Universal Augments capability-driven. **Art changes never adjust combat.**
- **Astra**: visual sheet calls J `Star Binding`, K `Astral Guard`, L `Stellar Circle`, I `Nova Alignment`; gameplay IDs remain `radiant_snare`, `prism_guard`, `solar_field`, `celestial_beam` unless gameplay spec explicitly changed.
- **Vex**: poster shows piercing J, dash K, ricochet L. Gameplay spec instead J `quick_barrage`, K `tactical_roll`, L `piercing_round`, I `bullet_storm`. **Gameplay spec wins**, poster only informs colors/effect shapes.
- **Boros**: poster shows cleave J, slam K, berserk L, finishing slash I. Gameplay spec instead J `ground_slam`, K `iron_resolve`, L `crushing_charge`, I `titans_fury`. **Gameplay spec wins**, poster only informs visual identity and reusable VFX elements.
- New Yuta-like swordfighter discussed later is **not** part of these three; never replace Boros without explicit approval.
- The term '100% automated' means user does not need to model, animate, pack or hand-edit; it does NOT mean concept-level artistic quality is guaranteed. Agent must report factual blockers and ask for aesthetic approval at gates.

## Free tool baseline
- Blender (GPL; scripting via `blender -b --python ...`) — models/rigs/poses/render. https://www.blender.org/
- Godot 4 GDScript (MIT; headless import/tests and native desktop builds) — scene/animation/VFX/map. https://godotengine.org/
- Python 3 + Pillow (PIL license), NumPy (BSD), optional OpenImageIO (BSD-style, verify build), optional ImageMagick (Apache 2.0) — pixel conversion, packing and QA.
- Pixelorama (MIT; optional manual/post-process only) https://pixelorama.org/ ; Krita (GPL; optional art editing) https://krita.org/ .
- Free assets: Kenney CC0 packs (verify each pack), Poly Haven CC0 3D textures/models/HDRIs (verify each asset), optionally Mixamo motions (free use subject to Adobe terms; NOT open-source/CC0, keep provenance and restrictions). No paid APIs or unlicensed IP required.
- Blender's `bpy` is **not** installed by pip as a substitute for its native runtime. Record exact Blender and Godot version in build log. CLI flags and renderer availability can vary by OS/version. Use pinned, locally validated commands.

## Output contract
`assets/source_3d/<character>/*.blend`, `assets/generated/characters/<character>/...`, `assets/generated/vfx/...`, `assets/maps/...`, `scenes/visual/...`, `tools/visual_pipeline/...`, `reports/visual_qa/<run_id>/...`, `licenses/asset_ledger.csv`, and reproducible `config/*.json`. Commit provenance and scripted generation; large binaries may be tracked separately according to repository policy.

## Deliverable definition
A clean Windows desktop Godot build featuring three selectable characters; consistent silhouettes at gameplay zoom; readable four-direction movement, attack/cast animations, visually layered VFX matching actual skills, three distinct arena styles, obstacle collision, enemy spawn safety, effect scaling with universal augments, recorded QA with PNG/GIF or MP4 evidence. Build acceptance is detailed in `06_TASKS_QA_ACCEPTANCE.md`.
