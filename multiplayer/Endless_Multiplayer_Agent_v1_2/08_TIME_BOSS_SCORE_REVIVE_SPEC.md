# 08 — Match Clock, Strict Boss Spawning, F Revive and Single-Map Demo (v1.2)

This document supersedes v1.1 map-transition/ticket rules. **LOCKED:** multiplayer EXP/level/augment per player; augment screen does not pause or protect; boss spawns every 180 simulation seconds whether earlier bosses survive; score = shared survival duration; hold F to revive and block basic and J/K/L/I/auto skill while reviving; a **single randomly generated/selected map remains for the entire run**. Solo mode unchanged.

## Clock and boss schedule
- Host owns integer `elapsed_match_ticks` and runs clock only during RUNNING. At default 60 physics ticks/s, scheduled boss due tick = `sequence * 180 * 60`. Match score is elapsed simulation ticks divided by tick rate. Clock is not paused during augment choice or revive.
- Spawn exactly one boss on every crossed due boundary, including if other bosses survive. Boss ID stable `(run_id, sequence)`. Boss death is idempotent. Do not cap/delay the **scheduled bosses** without explicit user approval. Optimize lesser mobs/projectiles separately.
- Clients receive `MATCH_CLOCK_SYNC`, `BOSS_SPAWNED`, `BOSS_DEFEATED`, and `MATCH_RESULT`; they never create authoritative boss instances based on local clock. Score freezes only on game over.

## ONE random map per run (new LOCKED behavior)
- In lobby/starting phase, host selects from eligible map templates and draws a fresh `map_seed` (or generates layout directly). Persist `map_id`, `map_seed`, `generator_version`, complete geometry/layout digest, and safe player/enemy spawn points under immutable `run_id`.
- Before unpausing the match, send `MAP_INIT` (run_id, map_id, seed, generator version, collision hash, optional canonical layout). Peers rebuild deterministically and reply `MAP_READY` with hash. If any peer differs, supply canonical geometry or reject the match, never allow mismatched collision.
- After `RUNNING`, **never** invoke `MAP_PREPARE`, `MAP_COMMIT`, map-ticket coordinators, map resets, boss-triggered transitions, or timer resets. Bosses die in the same map, award their configured rewards and update kill stats. New map can only occur for a distinct new `run_id`.
- Validate generated map traversability for playable regions and legal collision-free spawn points. All players share map, no separate instance per player.
- Late join, if later allowed, must receive the existing layout and run ID, not regenerate a fresh map.

## Downed/revive and augment
- Downed players require alive ally holding F in range (demo default 80 px for 4 s; revived HP 30%). Reviver cannot move, basic-attack, auto-attack, cast J/K/L/I or fire new offensive passive procs during channel. Still takes damage; release/out-of-range/CC/downed cancels. Host validates start/progress/complete and prevents double revives.
- Opening augment picker does not pause simulation and does not grant protection; combat may continue. Downed while picking hides UI, retains pending offer server-side, and never auto-selects.

## State and message contracts
Run lifecycle: `LOBBY → MAP_INIT → MAP_READY → RUNNING → GAME_OVER`.
Messages: `MAP_INIT`, `MAP_READY/REJECT`, `MATCH_CLOCK_SYNC`, `BOSS_SPAWNED`, `BOSS_DEFEATED`, `REVIVE_START/CANCEL`, `REVIVE_STARTED/PROGRESS/CANCELLED`, `PLAYER_REVIVED`, `MATCH_RESULT`.
`BOSS_SPAWNED` carries run ID, entity ID, sequence, due tick, actual tick, position and seed. All authoritative death/revive events must dedupe by stable ID. There are **no in-run map transition messages**.

## Test acceptance
1. Host starts 3 consecutive runs: each uses one host-selected random map; different seeds are generated. Different seeds need not guarantee visually different layouts in tiny template sets; check actual variety separately.
2. All 4 peers agree on map collision hash, player spawn positions and run ID before RUNNING.
3. 03:00 boss #1 spawns. If it survives, 06:00 boss #2 still spawns. 09:00 boss #3 spawns on schedule.
4. Kill any boss while others survive: world map hash, map instance identity and match clock remain unchanged. Kill last boss: no map transition.
5. Boss kill/reliable event replay cannot create duplicate rewards, kill count or boss instances.
6. Progression/EXP is independent per player; choosing augment does not pause or protect; death during choice is handled.
7. Holding F to revive disables all new basic/active/auto offensive casts, reviver still takes damage and can be interrupted.
8. Simulate 100/150ms RTT, 1–3% loss and four peers: map hash is consistent and boss schedule/score converge.
9. Host ends run and starts new `run_id`: only then is another random map selected. Solo level-based logic remains unchanged.
10. Automated tests plus 3–4 instance headless multiplayer runtime smoke tests; text-only logs/results, no screenshot/video export required.
