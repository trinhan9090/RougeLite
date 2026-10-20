# 05 — Agent Implementation Backlog & Acceptance

## Gates and order
**MP0 inventory**: Read old architecture/specs, list singleton assumptions, existing tests, current Godot version, existing player/EXP/Augment/boss/map APIs. Do not replace systems. Deliver written audit and migration plan.

**MP1 networking skeleton**: Host + join UI with IP/port, LAN handshake, max 4 total, reconnect/disconnect notifications, authority registration. **Pass:** same-machine host+client connection and rejection of 5th participant.

**MP2 per-player identity/movement**: spawn selected character uniquely, remote interpolation, local prediction and correction; other client cannot command another player. **Pass:** 4 participants walking simultaneously; 60 FPS target and movement not awaiting RTT.

**MP3 world authority**: enemies, boss AI, projectiles, hit/damage and VFX event matching. **Pass:** no duplicated HP decrements or casts at injected latency; enemy aggro includes all alive players.

**MP4 personal progression**: orb owner, independent levels/skills, individual three-choice offer queues; no pause, no protection. **Pass:** P1 level 9 while P2 remains level 3; both with different Augments; boss/map use shared match clock independently.

**MP5 death during picker**: test damage and death during picker; preserve pending offers and resolve lifecycle without auto-pick. **Pass:** HP decreases normally while menu open; picker never affects targeting or damage.

**MP6 boss/single-map**: match clock, strict boss spawn at 180s multiples, concurrent bosses, random map initialization once per run, seed/layout hash agreement, revive-by-F. **Pass:** boss spawns at 03:00 and 06:00 even if boss #1 lives; levels do not spawn bosses; boss death never triggers map change; score matches server clock.

**MP7 resilience**: invalid requests, duplicate RPC, packet loss, stale picks, crash/handoff. **Pass:** no XP duping, no rank duping, no soft-lock from pending offer. Explicit MVP policy if reconnect unavailable.

**MP8 full test**: host + 3 clients across LAN, then VPN if available; 30–150ms simulated RTT and 1–3% packet loss; measure correction, ping, jitter, bandwidth, fps, spawn budget. Return textual logs only.

## Mandatory tests (automate where possible)
| ID | Scenario | Assert |
|---|---|---|
| T01 | Host + client in localhost | connected, IDs unique |
| T02 | 4 total join | exact max accepted |
| T03 | 5th joins | rejected safely |
| T04 | Client spoof another ID | no cross-player movement |
| T05 | Two players reach same orb | one claimant and XP credit |
| T06 | Two people farm separately | levels diverge as expected |
| T07 | Level 3 / 6 / 9 / 11 P1 only | P1 skill unlocks only |
| T08 | P1 chooses Augment | P2 build unchanged |
| T09 | Open picker and receive hit | identical damage and aggro as no picker |
| T10 | Open picker then die | death occurs, no protection/auto-pick |
| T11 | Level 3 times quickly | offers queue ordered with no pause |
| T12 | Replay chosen offer RPC | rank increases once |
| T13 | Fake augment option | rejected |
| T14 | Choose obsolete eligible option | reject and refresh head offer |
| T15 | Client drops mid-picker | no global block |
| T16 | Client's skill casts with Split | only host deals hit/damage once |
| T17 | Two players reach level 10 | no boss spawn from levels |
| T18 | Boss #1 alive at 06:00 | spawn boss #2 anyway |
| T19 | Map seed mismatch | abort/resync; not diverging collisions |
| T20 | Auto/Manual differs by player | controlled independently |
| T21 | Damage from boss while picker open | normal HP loss, no special reduction |
| T22 | VFX duplication via cast replay | no duplicate render spam |
| T23 | Lost packet / latency simulation | measurable and stable; note issues |
| T24 | One-player solo | preexisting gameplay regression tests pass |
| T25 | Three participants of 4 slots | session works with 3, not hardwired to 4 |
| T26 | Four clients see same boss/map | phase, health and obstacle checksum agree |

## Acceptance measurements (DEMO DEFAULT targets)
- Host physics 60 Hz; rendering target 60 FPS on agreed PC baseline; user must provide actual hardware if required for strict benchmark.
- Typical local-LAN RTT aim < 15 ms; performance measured, never guaranteed.
- Stress: 4 total players, 100 enemies and 80 live projectiles (initial target; adjust if baseline cannot sustain). Peak network traffic per player recorded; target under 250 KiB/s downlink excluding asset downloads, subject to measured profiles.
- Test 30/60/100/150 ms RTT and 0/1/3% loss via network emulation if tooling available. Report observed numbers, never claim universal smoothness.
- No authoritative desync sustained after recovery window, no double XP/augment, no global freeze due to any picker.
- Provide `docs/reports/MPx.md`: modified files, commands, test output, failures, performance metrics and unresolved blockers. **No screenshot or video export requirement**.

## MP9. Time/score, multi-boss, revive regression suite (required)
| Test | Scenario | Expected |
|---|---|---|
| T27 | 02:59→03:00 | precisely one boss #1 on host and each client |
| T28 | Boss #1 alive at 06:00 | boss #2 exists concurrently, no delay |
| T29 | 09:00 and packet duplicate | exactly one boss #3 |
| T30 | Player jumps levels 9→20 | no boss from levels |
| T31 | Boss #1 dies while #2 lives | boss defeat deduplicated; map remains unchanged |
| T32 | Boss #2 dies, last active | boss defeat deduplicated; map remains unchanged |
| T33 | Old MAP_INIT replay | no regeneration/reload; run ID and map init version guard |
| T34 | Boss defeats | clock/score/boss schedule and map never reset |
| T35 | Late client clock sync | display converges, cannot trigger local boss |
| T36 | F hold near downed ally | revive progress; basic/autocast/J/K/L/I blocked |
| T37 | F release/leave range/CC | cancel; block releases, no revive |
| T38 | Reviver hit but not CC | reviver loses HP normally; no immunity |
| T39 | Player downed while Augment picker open | picker closes, offers retained, enemy AI continues |
| T40 | Whole team downed | match ends and score time frozen |
| T41 | Host simulation hitch crosses threshold | no skipped/duplicated due bosses |
| T42 | Four-player LAN artificial 100 ms RTT + 3% loss | bosses/clock/map hash/score eventually agree |
