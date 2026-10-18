# Vex/Boros north and dash correction — Fix03

Technical verification is recorded in regression.json and delivery.json. Owner visual approval remains pending. The attached sword image could not be downloaded for visual inspection. The user subsequently explicitly selected **downward carry beside the hip**, which is implemented and tested; visual approval remains pending.

## Changes

- Rear-facing Vex coat covers forward chest straps and waist ornaments; back scarf, heel profile and readable head beneath the hat. Boros rear mantle covers chest/forward hands; visible back hair and rear heels. Weapon is composited behind the body for north-facing Vex/Boros. Fixed96px canvas/feet48,76 retained, no horizontal-strip atlas sampling.
- Boros idle/run blade is angled downward from the hands beside the hip, away from the head. Attack/slam/guard/charge/Titan retain their distinct action poses. No skill geometry or gameplay changes.
- Vex Tactical Roll is K/slot2 in the locked data; L/slot3 remains Piercing Round. This fix applies to the **actual dash executor**, regardless of the user's informal skill numbering.
- Dash dust belongs only to the active TimedCombatEffect. The native attack-speed buff uses its own sparse32x16 ankle-chevron sheet, not a stretched dust frame. It follows the actual buff and disappears when that buff expires.
- ActorSprite synchronizes attack-flash state during motion and clears the old motion pose on exit. An explicit new action arriving immediately after the roll is retained. No extra gameplay cooldown, status, projectile or damage operation introduced.

## Evidence

`test_roster_corrections.gd` uses actual WASD and real K execution:34 checks. Confirms run_north, idle_north after stop, run_south, real roll lifetime, motion owner cleanup, no persistent roll pose, separate actual haste binding and zero aura after real expiry. GUI execution captures native640x360 and nearest1280x720 PNGs plus a real Godot movie, encoded to corrections.mp4.

`pose_tests.json`:151 checks, rear coat/heel differences for every run frame, no blade pixels over the head rectangle for idle/run in all directions, compact sparse haste frames. `asset_tests.json`:2382 native-frame checks across all720 frames.

`regression_initial.*` retains the initial legacy left-facing assertion failure: exit cleanup discarded a real new attack command. Correction respects explicit play_action commands; legacy49 checks and focused34 pass again. Final canonical suite count39. Live/packed verification uses focused34 + torso11 + roster28 + Astra22 =78 checks per environment. Packaged3-profile/3-boss smoke, GUI boot and ZIP integrity are required before delivery.json.

Reproduction: Python tools/art_v3/generate_roster.py; set ROUGELITE_TEST_OUT=reports/visual_qa/v3_fix03 then validate_roster.py and regress.py; test_fix03_pixels.py; Godot --headless --path . --editor --quit; Godot --script res://tests/integration/test_roster_corrections.gd. Capture: --fixed-fps 30 --write-movie reports/visual_qa/v3_fix03/corrections.avi. Blender only encodes the real movie. Original old assets/builds and prior evidence are preserved; deployment.json records the live rollback.

Launch title: **Three Heroes Pixel v3 Fix03**. Check upward movement with/without nearby enemies, sword carry while idle/running, the roll itself, the first frames after roll and the buff's expiry. The confirmed text choice resolves the carry pose; attachment pixels are not used. System Pictures/Videos are not writable; evidence remains in project reports.

Latest center correction: attached shield and Titan aura derive body center from shared SpriteFrames metadata body_center(48,52) minus feet_anchor(48,76), multiplied by actual sprite scale. Standard body center24px above feet; enlarged Titan30px above feet. Shield and aura share the same center while moving and changing size. Ground AoE/dash/haste decorations preserve their ground anchor; damage geometry unchanged. Captures astra_shield_center, boros_shield_center and boros_titan_center show actual K/I casts.

Shield-hit correction: accepted shield absorption emits a short guard_hit pulse using the defending shield context/renderer and body-center attachment. It no longer emits the incoming attack style as an unbound foot-centered shield circle. Real incoming-damage tests cover both Astra and Boros. Final focused count34, combined95 per source/live/packed environment.

Delivery preference update: user waived further image/video exports and will inspect directly in PLAY. Media generated before that instruction is not shipped in this correction delivery. Implementation, test logs, regression.json and docs are the review record. No new captures or encodes are required.

Final verification: **TECH_PASSED**.39/39 canonical suites;95 focused checks each in source/live/packed;151 pose and2382 native-frame checks;3-profile/3-boss release smoke, GUI boot and ZIP integrity all pass. No gameplay balance/collision/navigation changes. Current root Launch title Three Heroes Pixel v3 Fix03. Owner direct visual testing pending.
