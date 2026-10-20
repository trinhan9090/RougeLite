# Tofu acceptance results (2026-10-18)
Current source stage: PLAYABLE_TECH_TESTED; not USER_APPROVED. Evidence logs are local text, not mocked success.

| Case | Result | Evidence / limits |
|---|---|---|
| T01 manifest/paths | PASS local / PARTIAL archive |13originalfiles SHA256unchanged, DEF refs resolve; original archive checksum and supplied metadata absent |
| T02 sprite/offset | PASS |2064decoded, axis/flip/scale retained, selected11clips complete; Python hashes/atlas bounds |
| T03 AIR refs | PASS selected / source defects recorded |317occurrences,55unselected missing sprite refs; literal missing actions in dependency_graph.json |
| T04 SND playable | PASS decode / listening PENDING |320PCM entries hash/RIFFvalidated, offline catalog; no semantic voice claim |
| T05 palette/alpha | PASS extraction |RGBApixel hashes, source palette0, transparency; visual approval pending |
| T06 direction labels | PASS honest POC / 4DIR PENDING |44aliases but actual2_DIR_POC_ONLY, no fabricated rear view |
| T07 unlock/rank | PASS |3/6/9/11and4/4/4/3, registry validates |
| T08 Basic nearest | PASS |real melee10/15/30, no projectile, interval/range |
| T09 cooldown/aim | PASS |Manual last-attack aim per authoritative repo, Auto cluster, I range/cooldown refund |
| T10 boss CC | PASS |noJ/K/Istun/knockback on boss, halfLslow, I boss234 |
| T11 debris | PASS |40+12x7=124; rank3+48burn=172; finite6s and cleanup |
| T12 rush dedup | PASS |6x15/8x15, one hit per target per tick; wall stops |
| T13 chain | PASS |250/310, no overshoot, real retarget, maximum2switches |
| T14 projectile cores | PASS |Split/Pierce/Multishot/Homing rejected all5slots by capability |
| T15 geometry/VFX | PASS technical |Kexpanded123.2radius both damage and boundary, real source slam/debris spawned |
| T16 cleanup | PASS |Training reset, motion/fields/Echo removed; actual boss victory map transition |
| T17 seeded RNG | PASS |repeat20melee crit events identical under same seed |
| T18 missing source | PARTIAL / selected runtime robust |55broken unselected refs logged, runtime depends on generated local assets not rawSFF; no fake replacement for missing production art |
| T19 audio policy | PASS fallback / source voices PENDING |100accepted basics dispatch100original weapon cues,0voice; each active has1fallbackcue, source semantics not inferred |
| T20 stress | PASS execution / performance target OPEN |30real mobs/native1080p8s,2smokechecks0failures; p9551ms, not stable60FPS |

Current Launch --path . --script res://tests/integration/test_tofu.gd:88checks,0failures. Source --headless --path worktrees/visual_pipeline_v2 --script res://tests/integration/test_tofu.gd:88/0. Python tools/mugen_import/test_tofu.py:8testsOK. Actual stress --path . --script res://tests/integration/measure_tofu.gd:2/0. Twelve source regression suites:4hero+8core,0failures. Full48suites not rerun.

Initial failures retained in development logs: atlas bounds caught tall/scaledLpose and grid canvas was enlarged without resizing body; delayed Echo callback was bound to a freed cast node, corrected to static replay with strong config arguments;100Basic audit required correct slot_actions metadata; offline catalog relative URL fixed and tested. Initial stress harness used a Node2Dmethod on Node, corrected to viewport.get_visible_rect. None of those initial logs are final acceptance evidence. No gameplay values changed to mask failures.

Human checklist: select seventh avatar; move left/right/up/down and judge honest side-view poses/scale; Space/Auto basic combo; ManualJ/K/L/I; verify source slash/rush/debris/chain/spear feel and low visual clutter; listen to fallback SFX; source candidate audio bank review if wanted. No user modeling/editing/import steps required.
