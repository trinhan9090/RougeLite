# Ground zone targeting — 2026-10-18

User request: placed ground damage zones should focus nearest enemy, including Training boss.

Implemented: Astra L retains existing assistance; Viridian K, Tofu K and Graveshade K opt into the same existing nearest-with-facing-fallback targeting data. Controller excludes obstructed candidates for assisted placement. Auto density overrides removed for prison/debris/grenade. Zones snapshot enemy ground position on cast; they do not follow moving targets. No enemy: maximum-range last-attack direction in Manual, facing in Auto. Range, damage, cooldown, geometry, ticks, ranks and Augments unchanged. Self auras, near-caster mines, cones/dashes and beams/projectiles retain their behavior.

Verification environment: Godot4.7.2 stable, Windows, actual root Launch source, native1920x1080; GUI RTX3050 Laptop/OpenGL3.3, APPDATA=.local-data.

- test_ground_zone_targeting.gd actual GUI:40checks0failures; all four heroes, both modes, off-axis stationary immortal Training boss, initial and later damage, static cast center.
- test_ground_zone_selection.gd headless:48checks0failures; closer isolated enemy over dense cluster, dead/ally exclusion, wall occlusion, empty/out-of-range fallback, both modes.
- Existing Tofu88/88, Graveshade80/80, original full kits37/37, content31/31.
- Viridian77/77 assertions after updating old density expectation and isolating area-expansion/boss fixtures. Existing root mapped_actor_effects.gd signal callback emits an argument-count diagnostic during projectile visual attachment; pre-existing, not changed in this targeting patch. Thus this suite is not claimed diagnostic-clean.
- Full test runner not executed. Both new suites registered.
- Initial selection test had untyped conditional array assignment; corrected typed assignment. Initial Viridian fixture update mutated shared candidates via Array.assign; corrected detached typed fixture. Failed development logs retained.
- Initial Python run from root could not read historical Git object9f0aea8. Re-run from existing source branch uses its valid history; see ground_zone_python_verified.log.

Files: three character loadouts and generators, skill_controller.gd, control_mage_executor.gd, melee_sequence_executor.gd, tactical_executor.gd, two new ground-zone tests, adjusted test_viridian.gd and test_tofu.py, tests/run_all.gd, docs/04_TASKS.md,05_DECISIONS.md,WORK_LOG.md. All runtime edits mirrored into current root Launch source. No raw art/audio changes or QA media exports. Restart Launch.cmd and try the four zones in Training with boss beside/behind facing. Human visual acceptance pending.
