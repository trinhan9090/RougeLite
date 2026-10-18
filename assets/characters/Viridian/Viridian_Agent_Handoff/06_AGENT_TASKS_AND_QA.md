# 06 — AI Agent tasks, dependencies and acceptance

## Work protocol
Create work branch; inspect current repository and active asset chain; do not overwrite existing character data. Record CLI versions. Report evidence path for every claim. No silent dependency installation without approval if it changes user's machine globally.

| Milestone | Deliverable | Acceptance criteria |
|---|---|---|
| V0 Source audit | DEF/CNS/CMD/AIR manifest, SHA hashes | base/Maro resolved, missing refs flagged |
| V1 Extract | decoded SFF/PNG, SND/audio + import logs | count exports, corrupt frames flagged, no source writes |
| V2 Catalog | offline HTML sprite/animation/sound, move mapping CSV | preview plays; 5 move candidates findable; unverified labeled |
| V3 Visual prototype | unique original/fallback Viridian 4-dir sprite plus effects | readable 4-dir without misleading mirroring; nearest pixels |
| V4 Data/Combat | character + basic + J/K/L/I data | skills unlock 3/6/9/11, independent hitbox and visual |
| V5 VFX/SFX | full 5 attack displays incl cleanup | width/count/radius modifiers reflected; no leaks |
| V6 Augment tests | compatibility matrix and proc safety | split works on basic, not beams; no recursion |
| V7 Runtime QA | map, bosses, 30+ mobs | 60fps goal on target machine (report hardware, percentile) |
| V8 User review | playable local build, screenshots, clips, diff | reviewer sees limitations and accepts/rejects |

## Automated tests
T01 manifest paths; T02 sprite IDs and frame offsets; T03 AIR action refs; T04 SND indexes playable; T05 palette/alpha; T06 four directions labeled correctly; T07 unlock/rank caps; T08 auto nearest target; T09 cooldown/range/aim; T10 status boss CC cap; T11 shield amount/expiry; T12 orbit proc cooldown; T13 multibeam max hit cap; T14 Split eligibility on basic only; T15 collision/hit visuals sync; T16 map cleanup; T17 deterministic random when seeded; T18 broken/absent SFF gracefully falls back; T19 SFX loops always stop; T20 30+ enemies stress test.

## Required evidence directory
`reports/viridian/YYYYMMDD/` with `source_audit.md`, `skill_mapping.csv`, `png_contact_sheet.png`, `animation_preview.html`, `sound_catalog.html`, `godot_test.log`, `fps_metrics.csv`, `preview_basic.mp4`, `preview_J.mp4`, `preview_K.mp4`, `preview_L.mp4`, `preview_I.mp4`, `user_review_checklist.md`.

## No-false-success rules
Not done merely because files exist. Distinguish `EXTRACTED`, `DECODED`, `MAPPED`, `INTEGRATED`, `PLAYTESTED`, `USER_APPROVED`. Only mark `USER_APPROVED` after actual user acceptance. If exports require manual or unlicensed tools unavailable to agent, surface blocker; do not fabricate evidence. Existing visual three-character priority takes precedence if the user wants sequential implementation.
