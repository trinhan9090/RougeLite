# 06 — AGENT TASKS, TESTS & ACCEPTANCE

## Milestones — thực hiện theo thứ tự
**P0 Audit**: inventory files + hashes + correct DEF; command/state source map; confirmed SFF/SND decoding, asset rights log. PASS if inventory reports every failed/unknown decode.

**P1 Extract & Preview locally**: extract sprite PNG/SND WAV into staging, parse AIR and offsets; locally inspect playback in tool or Godot. Không nộp ảnh/video. PASS if ≥90% referenced animation frames resolved or blockers clearly documented; no incorrectly fabricated assets.

**P2 Character Runtime**: add character registration, stats, movement, nearest-target basic attack, skill unlock levels. PASS if manual and auto controls and existing three characters regression pass.

**P3 J & K**: bursts and grenades with real projectiles/area damage; VFX and SFX verified/mapped. PASS if damage matches true hit events, scene no desync.

**P4 L & I**: mines with cap/detonation, rocket/cluster effects, boss-safe handling. PASS if deterministic spawn, timers, wall collision and event dedupe.

**P5 Augments**: split/pierce/echo, AOE+, conflict branches and eligibility. PASS if a shared Split mechanic works both Graveshade and Astra/Vex, not duplicated code.

**P6 Stress & Release**: 30/60/120 enemies as local stress probes, 4 players is future only; playtest all skills, check CPU/memory/particle and sound counts; script-run tests; update test logs. NO screenshot/video outputs. Integrate in working tree only after approval/tests if repo policy demands.

## Required test matrix
T01 archive decompression safe, T02 DEF references exist, T03 AIR frames resolve, T04 SND mapped to real sounds, T05 sound plays only for approved events, T06 right/left offsets consistent, T07 no fake north/south, T08 nearest-target attack, T09 no attack out of range, T10 J shot count/angle correct, T11 K explosion once per target, T12 K obstacle behavior, T13 L capped mines, T14 L expiry removes collision, T15 L chain detonate one-shot, T16 I projectiles/cooldown, T17 I no multi-hit duplicate, T18 Auto/Manual parity, T19 skills only at 3/6/9/11, T20 rank caps, T21 Split eligible bullets/blocked mines, T22 conflict lock bidirectional, T23 no recursion, T24 pause/resume + level screen, T25 no regression Astra/Vex/Boros, T26 Godot headless project load, T27 continuous 10 minute game run, T28 sound peak/voice budget, T29 30+ mob readability via live inspection, T30 no altered files outside scope.

## Output chỉ text/log
- `reports/graveshade_source_audit.md`
- `reports/graveshade_state_mapping.csv`
- `reports/graveshade_tests.md` (test id PASS/FAIL/SKIP + invocation + trace)
- `reports/graveshade_changes.md`
- `reports/graveshade_blockers.md`
- Working Godot project assets and scenes.

Người dùng chỉ thử chơi trực tiếp; không yêu cầu quay hoặc gửi ảnh, video. Nếu Agent không có công cụ đọc sprite/SND hoặc môi trường Godot, phải báo BLOCKED, không đánh dấu PASS.
