# Three Heroes Pixel v3 — technical review

Owner visual approval: **PENDING**. Original simplified pixel implementation; concept fidelity is not self-certified. Current evidence is original authored 2D pixels, not Blender model renders and not cropped concept art.

## Scope

- Standard enemies: actual damage capsule24x32 centered18px above feet; navigation remains13px grounded circle. Straight projectiles, Pierce, prediction, beam intersection and impact sparks use torso reception. Walls still block hits. Ground AoE/melee range, bosses, stats, skill rank tables, progression and spawning are unchanged.
- Astra/Vex/Boros:720 separate96x96 RGBA frames, nine action states, four directions, fixed feet48,76. No eye/mouth detail. Vex retains wide hat/red scarf/two pistols; Boros retains hair/steel shoulders/red mantle/greatsword. Astra face detail removed consistently. Original previous sprite assets preserved.
- All15 basic/active presentations use one shared PixelVisualEffect/CombatVisualFactory/ActorSprite pipeline. Actual projectile creation drives recoil/muzzle flashes. Buff and shield decorations read real gameplay state; dash decorations are children of the true motion executor.

| Hero | Basic | J | K | L | I |
|---|---|---|---|---|---|
| Vex | gold tracer/muzzle/torso spark | four real shots at rank1 | rolling pose/dust + actual haste buff feedback | long piercing tracer; native mark brackets at rank4 | actual timed bullet stream; accepted native ricochet tracer |
| Boros | steel/red directional slash | real-radius slam and native second wave | iron shell bound to ShieldInstance | charge pose/dust and rank4 damaging trail | aura bound to actual Titan buff; native pulse uses actual burst event |

Advanced effects do not invent extra damage, bullets, buff duration or hitboxes. Native reflection/healing retain standard impact/health feedback rather than separate cinematic animations.

## Evidence and reproduction

- `asset_tests.json`:2382 checks,720 frames; fixed canvas, hard alpha, animated states, no clipped frame edges, fixed anchor/palette metadata.
- `regression.json`/`regression_bounded.log`: canonical isolated Godot suite status. `regression_initial.*` preserves the initial obsolete aiming assertion failure. It assumed every lead vector points down, which is false when aiming at an elevated torso; replacement checks analytic intercept and real moving-target damage.
- `test_torso_hurtbox.gd`:11 real-physics checks including upper-body hit, foot-only miss, two-enemy Pierce, wall-blocked projectile/beam, preserved locomotion and torso impact placement.
- `test_roster_pixel.gd`:28 checks using both actual loadouts/executors, real damage, exactly4 Barrage/18 Storm shots at rank1, real shield/buff/dash bindings and trail cleanup. Astra correction suite adds22 checks.
- `vex.mp4`, `boros.mp4`, `vex_advanced.mp4`, `boros_advanced.mp4`: four20-second Godot recordings,1280x720/30fps. Base/advanced screenshots have native640x360 and nearest2x versions. Contact sheets and concept/native crop comparison boards included.
- Capture fixture: unlocked skills, high enemy HP, cleared local obstacles and stationary targets to expose every effect. These are QA overrides, not production balance changes. Gameplay code performs every cast/hit. Crowd performance runs separately with live AI.
- `vex_performance.json`/`boros_performance.json`:600 measured frames each,33 enemies,12 forced skill cycles. Ryzen5 6600H/RTX3050 Laptop, Godot4.7.2 GL Compatibility. Mean145.34/144.76FPS; p9513.54/12.45ms;1% low64.80/67.44FPS. Measurements are local and do not guarantee other machines. Temporary effects capped80; projectile trails capped120.

Commands: `python -X utf8 tools/art_v3/generate_roster.py`; `python -X utf8 tools/art_v3/configure_roster.py`; `python -X utf8 tools/art_v3/validate_roster.py`; Godot `--headless --path . --editor --quit`; `ROUGELITE_TEST_OUT=reports/visual_qa/v3_three_heroes python tools/art_v3/regress.py`; Godot `--fixed-fps 30 --write-movie ...avi --script res://tools/art_v3/capture_roster.gd -- --hero=vex [--advanced]`; Blender `encode_video.py` encodes actual AVI only. Use the same commands with boros.

`delivery.json` is written only after source suites, live import,61 focused checks in live and packed projects,3-profile/3-boss packaged smoke, GUI boot and ZIP integrity pass. `deployment.json` records hashes and reversible live backup. Build uses official portable runtime/PCK, no paid/export template dependency.

## Play review

Run project-root `Launch.cmd`; title must say **Three Heroes Pixel v3**. Choose CHARACTER to inspect Vex/Boros, PLAY for normal progression or Art Preview for all unlocked skills. Check north/south feet, readable roll/charge, bullet entry on torso, shield break/expiry, Titan expiry, native rank upgrades and Manual facing. J/K/L/I normal unlock levels remain3/6/9/11.

Remaining: owner art approval; simplified silhouettes have less detail than concepts. Remaining biomes/boss artwork and final all-device acceptance are separate unchecked milestones. System Pictures/Videos folders are not writable in this session; media is under the project reports directory. Blender reports a denied optional extension-cache write, but successful MP4 encoding is verified by `VIDEO_ENCODE_OK` and real output files.

Final status: **TECH_PASSED**. Source38/38 suites;2382 pixel checks;61 focused checks each in source/live/packed resources; packaged3-profile/3-boss smoke and GUI boot pass. Normal PLAY recordings vex_normal.mp4/boros_normal.mp4 use production stats/AI/progression and finish alive. Packaged focused tests run external script files against the exported res:// resources, because tests are intentionally excluded from shipping PCK. Initial harness-path error retained in packed_harness_initial.log. Build SHA256: `c648074b6e176f05ea8073f0069526c1c701fa399ddcecdd56bb7e466824a59b`.
