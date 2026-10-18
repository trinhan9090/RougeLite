# Doom ultimate / Punisher explosion correction

Task: COMBAT-VFX-01. Date: 2026-10-17. Branch: fix/doom-rays-punisher-vfx.

## Changes
- Doom/ Viridian I previously tested each ray only on its emission tick. Each ray now retains a separate origin, direction, width, expiry and target-hit set for its visible 0.18 seconds. A torso entering a visible ray can be hit; an expired lane cannot hit. A stationary target cannot take repeated frame hits from the same ray. Existing two-hits-per-target root budget, ray counts, damage, fan angle, range and Area Expand remain unchanged.
- Already emitted rays stay at their emitted world location when the caster moves. The last ray now remains queryable until its actual visual expiry instead of disappearing with the channel runtime. The rank3 final burst still fires once at the original channel end. Thin green lane boundaries make each ray's width readable. Existing shared torso physics queries and wall/faction filters remain in use.
- Punisher/Graveshade explosion sprites use 60% of their previous diameter, maximum0.24s instead of0.35s, alpha0.8. Source MUGEN art and explosion audio retained. A thin ring keeps the actual damage radius readable.
- Burning ground is a faint ground area for its existing3s rather than a repeating full explosion animation. Damage ticks use a small boundary pulse, with no extra explosion sprites. No damage/cooldown/area/rank data or shared combat/augment interfaces changed.

## Modified code and tests
- scripts/combat/control_mage_runtime.gd
- scripts/ui/mapped_actor_effects.gd
- scripts/ui/mapped_sprite_effect.gd
- scripts/ui/tactical_actor_effects.gd
- scripts/ui/tactical_visual.gd
- tests/integration/test_viridian.gd
- tests/integration/test_graveshade.gd
- docs/04_TASKS.md, docs/WORK_LOG.md and this report.

## Verification
Godot4.7.2.stable.official.ed1daf0bf, Windows, Compatibility renderer.
Commands use tools/godot/Godot_v4.7.2-stable_win64_console.exe and APPDATA=.local-data.
- Source import: --headless --path worktrees/visual_pipeline_v2 --editor --quit.
- Source focused: --headless --path worktrees/visual_pipeline_v2 --script res://tests/integration/test_viridian.gd (77checks,0failures).
- Source focused: --headless --path worktrees/visual_pipeline_v2 --script res://tests/integration/test_graveshade.gd (80checks,0failures).
- Current actual Launch project, graphical window: --path . --script res://tests/integration/test_viridian.gd (79checks,0failures).
- Current actual Launch project, graphical Punisher test: --path . --script res://tests/integration/test_graveshade.gd (81checks,0failures).
- Complete regression re-running with APPDATA=.local-data/qa_combat_vfx_fix for default keybindings. The first full run was interrupted when the pre-existing training UI suite assumed Space despite a persisted custom basic binding, then indexed a missing damage label and stalled. This was reproduced independently; gameplay settings were not reset. Fresh QA settings isolate the existing default-binding assumption. Final regression result appended after completion.
- New tests exercise real torso entry, lane gaps, expiry, per-ray dedup and presentation sizes/ground state. Existing suites retain rank3 endpoint burst, global hit cap, Auto/Manual, actual PLAY, boss transition and shared Augment checks.
- First Punisher assertion used exact float equality for126px and failed due to floating point multiplication; changed to approximate numerical equality, then focused rerun passed. No combat data changed to satisfy the assertion.

## Deployment and limitations
Root source promoted with baseline8ea19b3 byte-normalized prechecks and backup; journal reports/ray_fix_deployment.json. Restart Launch.cmd to load it. Existing PCK/ZIP builds were not rebuilt.
No QA images/videos exported. Human visual acceptance pending. No new FPS measurement or stable60FPS claim. Source art remains side-view and private-local with unresolved third-party distribution rights. This focused fix does not close the broader VIRIDIAN-01/GRAVESHADE-01 gates.

## Final verification status
- 45 distinct regression suites confirmed with zero failures:37 completed in ray_fix_regression_isolated.log plus8 in ray_fix_remaining.log. The transport session was lost during test_bound_offers.gd; no final result was captured for that suite. Do not claim46/46. No failures/errors were found in the45 completed suites.
- Current Launch GUI: Doom79checks/0failures; Punisher81checks/0failures. Focused tests and actual PLAY/TRAINING passed.
- Source implementation deployed; human visual approval and the unconfirmed bound-offers suite remain outstanding. Canonical focused task stays unchecked to keep those gates explicit.
