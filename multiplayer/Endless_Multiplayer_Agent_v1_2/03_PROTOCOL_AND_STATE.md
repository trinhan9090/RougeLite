# 03 — Versioned Protocol & State Machines

## P1. Packet envelope
All protocol payloads use `protocol_version`, `run_id`, `sender_peer_id` (validated; informational only), `server_tick` when host-sent, `seq`, `message_type`, `payload`. Reject incompatible versions. Version initial = 1; fix serialization schema before broad implementation.

## P2. Core messages
| Name | Direction | Payload/semantics |
|---|---|---|
| `JOIN_REQUEST` | C→H | protocol, selected character, client nonce |
| `JOIN_ACCEPT/REJECT` | H→C | assigned player ID, run ID, reason |
| `PLAYER_INPUT` | C→H | tick, input_seq, move vector, aim angle, skill button states; no HP/damage |
| `WORLD_SNAPSHOT` | H→C | tick, compact player/enemy states, health, position/velocity, event watermarks |
| `ORB_SPAWNED/ORB_CONSUMED` | H→C | unique orb ID, amount, claimant, authoritative EXP delta |
| `LEVEL_CHANGED` | H→owner/all | player ID, new level, XP and skill unlock effects |
| `AUGMENT_OFFER` | H→owner | offer_id, offer_seq, level_earned, 3 `offer_option_id`s, type/target/rank info |
| `AUGMENT_PICK` | owner→H | offer_id, option_id, request_id; NEVER client stat values |
| `AUGMENT_APPLIED/REJECTED` | H→owner (+summary to peers) | offer_id, augment ID, slot, rank, current pending head, reason |
| `CAST_REQUEST` | owner→H | cast_seq, skill slot, target vector or entity ID, input tick |
| `CAST_ACCEPTED/REJECTED` | H→peers/owner | cast ID, origin, direction, tick, skill/augment snapshot, deterministic seed |
| `COMBAT_RESULT` | H→C | event ID, health/shield deltas, status flags, affected entities |
| `BOSS_SPAWNED/DEFEATED` | H→C | boss_sequence, boss_id, scheduled_tick, actual_tick, difficulty tier, spawn position, unique event ID |
| `MATCH_CLOCK_SYNC` | H→C | elapsed_tick, tick_rate, server_tick, next_boss_sequence, score_seconds, active boss ids |
| `MAP_INIT` | H→C | run ID, map ID, random seed, generator version, collision layout hash |
| `REVIVE_START/CANCEL` | C→H | downed target id, input seq; host validates F hold and range |
| `REVIVE_STARTED/PROGRESS/CANCELLED` | H→C | reviver id, target id, revive id, progress ticks, reason |
| `MAP_READY/REJECT` | C→H | run ID, map layout hash, readiness or mismatch reason |
| `PLAYER_DOWNED/DEAD/REVIVED` | H→C | player ID, tick, lifecycle status |

## P3. Offer state machine (per player)
`NONE → QUEUED → DISPLAYED → PICK_SENT → APPLIED → DISPLAY_NEXT`.
- Creation is server-only, one per level gained; `offer_seq` strictly increasing per player.
- Network retransmission of `AUGMENT_PICK` with identical `request_id` must return same result without reapplying.
- Replayed request with wrong ownership, stale offer_id, fake option_id or nonhead offer must reject.
- `AUGMENT_REJECTED` can produce refreshed offers; do not consume a level-up on failed validation.
- Death while DISPLAYED/PICK_SENT: host resolves damage normally; on DOWNED/DEAD client hides picker, retains queued offers; delivery after respawn/revive according to chosen lifecycle. No iframes or auto-roll.
- Stale ACK after player death must not resurrect or apply stats silently; host explicitly rejects choice from downed/dead state, client reconciles.

## P4. Player lifecycle
`CONNECTED → ACTIVE → DOWNED? → REVIVED? → DEAD → SPECTATOR? → DISCONNECTED`. DOWNED/REVIVE and spectator are optional feature gates. Do not introduce implicit immunity or idle-time protections at any state transition. Keep per-player run data server-side. Reconnect rules for initial MVP: if unsupported, mark explicitly and terminate that player's participation without soft-locking map/boss.

## P5. Single map per run and strict timed bosses
`LOBBY → MAP_INIT → MAP_READY (all participants) → RUNNING → GAME_OVER`.
- Host is authoritative for random map template/seed, layout, obstacle collisions and player/boss spawn positions. A new run selects a new random map; no map changes within a run.
- Clients acknowledge the host-approved layout hash and generator version. On mismatch, host sends canonical layout or denies joining; never start inconsistent geometry.
- Boss appears at elapsed 03:00, 06:00, 09:00, etc., even if earlier bosses survive. Player level never schedules bosses. Death of boss grants normal rewards and kill count only, never reloads/regenerates map.
- During running there are no map transition events, map tickets, load freezes or world resets.
- All events carry run ID and stable entity IDs for deduplication.

## P6. Sample offer and pick JSON (illustrative wire shape, not Godot serialization constraint)
```json
{"protocol_version":1,"run_id":"run_23","message_type":"AUGMENT_OFFER","server_tick":1542,"seq":11,"payload":{"player_id":2,"offer_id":"r23-p2-o8","offer_seq":8,"level_earned":9,"options":[{"option_id":"a","augment_id":"stat_damage","target_slot":null},{"option_id":"b","augment_id":"projectile_split","target_slot":"basic"},{"option_id":"c","augment_id":"skill_rank_up","target_slot":"J"}]}}
```
```json
{"protocol_version":1,"run_id":"run_23","message_type":"AUGMENT_PICK","seq":101,"payload":{"offer_id":"r23-p2-o8","option_id":"b","request_id":"p2-81"}}
```

## P7. Game event deduplication
For cast effects, send `cast_id` for each accepted cast; client predicted VFX reconciles or is cancelled if rejected. Damage event `event_id` unique within run. Repeated events must not duplicate HP changes, audio, XP or augment procs. Server owns kill attribution and projectile damage; clients never submit collision results as truth.
