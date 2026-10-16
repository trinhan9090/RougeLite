# Art demo acceptance — 2026-10-16

Playable original procedural **prototype** demo, with subjective art approval pending. Gameplay mechanics, unlocks, ranks, colliders, seeded systems and Auto/Manual rules were preserved. Manual aims along last movement/facing.

## Reproducible evidence

Environment: Godot4.7.2.stable.official.ed1daf0bf, Windows, Compatibility/OpenGL3.3, NVIDIA RTX3050 Laptop GPU, AMD Ryzen5 6600H; Python3.12.14/Pillow12.3.0. Logs under `docs/art_baseline/`.

| Gate | Command/result |
|---|---|
| Original assets | `finalize_report.py`:241 original asset files hashed, zero changed.457-file pre-change source snapshot and inventory retained. |
| Pipeline | `test_pipeline.py`:6 unittest cases pass, including schema keyword/negative tests,15 VFX schemas,636 actual body frames, deterministic output and cardinal differences. `validate.py`: all3 manifests pass. |
| Import/parse | Godot `--headless --path . --editor --quit`; `--script res://tools/art_pipeline/import_frames.gd`: ART_IMPORT_OK heroes=3 clips=108. |
| Shared character renderer | `test_art_frames.gd`:228 checks pass; separate128px PNG frames,4 facings, all clips, weapon layer, unchanged14px collider, pause/death. |
| Real VFX | `test_art_vfx.gd`:41 checks pass;15 actual executors, real projectile binding, split AstraJ/VexL, negative BorosJ, geometry/caps/pause. |
| Maps |3 themes ×100 seeds;3300 checks pass: connected navigation, safe250 start, tile layer with no physics, obstacle collision alignment. |
| Gameplay regression | `--script res://tests/run_all.gd`:33 suites failures0; zero ERROR/WARNING diagnostics. Includes input/facing, shared augments, full kits/edges, upgrades, boss/map transitions and hazards. Final presentation-only weapon/pause changes additionally rechecked by focused art suites and actual renderer captures. |
| Renderer | `capture_preview.gd`:48 captures, failures0;15 actual actions,24 run frames and9 maps at seeds1/42/999.3 GIFs and review gallery generated from actual renders. |
| Windows | `tools/package.ps1`: exported PCK + official portable runtime, standalone RELEASE_SMOKE_OK profiles=3 boss_victories=3. Legacy unverified frame resources excluded and asserted absent by packed smoke test. |

The full suite and focused reruns are separate evidence; no claim that an unrun command passed. Earlier interrupted runs, invalid-fixture measurements and their diagnostics are retained rather than represented as final passes.

## Measured performance — target NOT met

GPU-rendered60-frame samples,300 actual swept projectiles,120 projectile visual children maximum,80 impact effects maximum.20 visible XP-orb fixtures are held without collection to prevent upgrade pauses. Explicit fixture populations200/400 exceed production cap110; the production cap was not changed. These are short workstation measurements, not a certified benchmark.

| Enemies | Median frame ms | p95 frame ms | Functional fixture |
|---:|---:|---:|---|
|100|16.256|23.555|pass;300 projectiles retained|
|200|19.947|34.972|pass;300 projectiles retained|
|400|64.093|93.246|pass;300 projectiles retained|

**60 FPS at100 enemies/300 projectiles is not achieved. A8 remains unchecked for performance acceptance.** No spawn/skill numbers were reduced to conceal this. See stress.log and the screenshots for measured load.

Static projectile art is now drawn once and transformed with its real projectile parent, rather than rebuilding draw commands every frame. The prior sustained-load baseline is preserved in stress_before_static_draw_cache.log (100 enemies: median32.836ms/p9571.856ms). The final sample is near60FPS at the median but does not demonstrate stable60FPS at p95.

## Review and limitations

Run `builds/windows/Play.cmd` or the Windows archive. PLAY starts ordinary gameplay. CHARACTER → **Xem đồ họa / Art preview** exposes real basic/J/K/L/I executors and ranks without altering saved settings or production content. Four-direction contact sheets, action screenshots, GIFs and map views are in `screenshots/art/index.html`.

Visuals are procedural prototypes: four cardinal facings, simple poses and original silhouettes; they are not represented as matching the detail/polish of the supplied concepts. Enemies/loot/bosses retain the existing readable placeholder style. Owner visual approval is PENDING. Optional Web export was NOT EXECUTED; no locally installed Web template is assumed. Git main has no commits and the environment marks .git read-only; no commit was made.
