# 02 — Runtime Network Architecture

## N1. Topology
Use one **listen server** (host also plays) and up to 3 additional clients. Godot 4 `ENetMultiplayerPeer` over UDP. LAN IP and VPN virtual IP are accepted. Default port `24567/UDP` is configurable. Direct Internet without VPN may require router UDP port forwarding; VPN relays can increase latency. No unconditional promise of lag-free play. Host leaving terminates MVP run (no host migration). Join in-progress disabled for first MVP; reconnect with existing token may be supported after core tests.

## N2. Authority matrix
| Object/data | Source of truth | Client may predict? |
|---|---|---|
| Position / movement | host simulation | local owned movement only + reconciliation |
| Enemy & boss AI and state | host | interpolate visuals only |
| HP/shield/death | host | feedback preview only |
| Skill cooldown/cast approval | host | owned anticipation VFX, dedupe by cast ID |
| Projectiles/hits/damage | host | visual ballistic prediction only |
| EXP orb claim, XP, levels | host | pickup animation only |
| Augment offers/ranks/eligibility | host | presentation only |
| Map seed/obstacles | host | deterministic generation then checksum handshake |
| Sound/particles/camera | local renderer | yes; never authority |

## N3. Tick and clocks
Host physics fixed timestep target 60 Hz, monotonic simulation tick and `run_id`. Player input packets 30–60 Hz, server snapshots players ~20–30 Hz and enemies ~10–20 Hz (all tunable/profilable). Use float accumulator or built-in physics clock, not wall-clock-based arbitrary deltas. Clients interpolate remote entities with buffer (~100 ms initial), and locally predict own character. Reconcile corrections without large snaps when possible. Combat results are strictly host decided.

## N4. Transport channels
- Input: `unreliable_ordered` channel 1 with `input_seq`, current and redundant previous input frames.
- Snapshots: `unreliable_ordered` channel 2 with snapshot/tick IDs.
- Gameplay events/confirmations: `reliable` channel 3 for orb consumed, offer created/chosen, cast accepted, timed boss spawn, boss death/initial map handshake, lifecycle and roster.
- Noncritical VFX: lightweight events/cast seed on separate unreliable channel if recoverable; no per-particle sync.
- Rare full-state snapshots on reliable channel only during join/reconnect/map resync, not every frame.
Use explicit RPC sender validation. A client cannot call authoritative apply-damage/award-XP functions.

## N5. Identity and trust
Assign `player_id` on host; validate `multiplayer.get_remote_sender_id()` against membership before accepting input/choices. Enforce message size/rate limits, positive ranges and entity ownership. Prevent duplicate offer application and orb consumption with idempotency maps. Separate `player_id`, `peer_id`, and `character_id`; never trust username or supplied damage amount. For private LAN, simple session tokens suffice for prototype; avoid storing secret keys in source.

## N6. Visibility/performance
Spatially partition enemies, replicate relevant fields only, prefer dead-reckoning and correction; use reliable spawn/despawn event plus periodic snapshots. Do not network individual animation frames, SpriteFrames, sounds, hit spark particles or GPU emissions. Visual runtime reconstructs from authoritative event payload and seed. Rate limit projectiles and augment proc chains; maintain `source_skill_id`, `cast_id`, `projectile_id`, `generation_depth` and `trigger_policy`.

## N7. Desync detection
Every 2–5s emit diagnostic state summary (run/elapsed_match_tick/boss_sequence/map seed/obstacle digest/roster/character level and XP/active boss IDs, next 180s spawn boundary, survival score). Log if diverged; request full authoritative snapshot instead of trying to repair by arbitrary client-only simulation. Log ping, jitter, packet loss, correction magnitude, tick debt, per-peer bandwidth. Profile with 1/2/4 players and enemies/projectiles stress.
