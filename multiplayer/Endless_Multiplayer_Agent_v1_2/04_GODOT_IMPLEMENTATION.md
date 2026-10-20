# 04 — Godot Integration Plan

## I1. Modules (names adaptable, responsibilities not)
```text
res://multiplayer/
  network_manager.gd             # ENet peer lifecycle
  session_manager.gd             # roster, host/join, authorization
  net_protocol.gd                # versioning and (de)serialization
  input_replication.gd           # client inputs, sequence numbers
  snapshot_replication.gd        # delta/relevance and interpolation
  prediction_reconciliation.gd   # owned-player only
  authoritative_world.gd         # server simulation bridge
  exp_orb_authority.gd           # atomic per-player pickup
  augment_offer_authority.gd     # per-player offer queue and validation
  time_encounter_director.gd     # strict 180s boss cadence + stable boss ids
  match_clock_authority.gd       # authoritative tick-driven survival score
  revive_authority.gd            # F-channel revive, combat lock
  map_sync.gd                    # ONE-TIME run-start seed/layout/checksum handshake
  net_diagnostics.gd             # RTT, tick drift, traffic, errors
res://ui/multiplayer/host_join.tscn
res://ui/augments/player_offer_picker.tscn
res://tests/multiplayer/
```

## I2. ENet setup minimal skeleton
```gdscript
# network_manager.gd: example adapter; integrate with existing scene ownership.
extends Node
const DEFAULT_PORT := 24567
const MAX_TOTAL_PLAYERS := 4

func start_host(port: int = DEFAULT_PORT) -> Error:
    var peer := ENetMultiplayerPeer.new()
    var err := peer.create_server(port, MAX_TOTAL_PLAYERS - 1)
    if err != OK:
        return err
    multiplayer.multiplayer_peer = peer
    return OK

func join_host(address: String, port: int = DEFAULT_PORT) -> Error:
    var peer := ENetMultiplayerPeer.new()
    var err := peer.create_client(address, port)
    if err != OK:
        return err
    multiplayer.multiplayer_peer = peer
    return OK
```
Godot peer limits and actual connections MUST be tested; use host membership validation as final four-player cap. In production use proper connection error/disconnect handling and show errors in UI.

## I3. Authority boundary interfaces
```gdscript
# Interface contracts (pseudocode): concrete runtime scripts may differ.
func server_apply_input(player_id: int, input_frame: Dictionary) -> void
func server_try_claim_orb(player_id: int, orb_id: int) -> bool
func server_grant_exp(player_id: int, amount: int, source_id: int) -> void
func server_queue_offer(player_id: int, level_earned: int) -> void
func server_try_pick(player_id: int, offer_id: String, option_id: String, request_id: String) -> Dictionary
func server_spawn_scheduled_boss(boss_sequence: int, scheduled_tick: int) -> void
func server_init_random_map(run_id: String) -> Dictionary
func server_begin_revive(reviver_id: int, downed_target_id: int) -> void
func server_validate_cast(player_id: int, skill_slot: String, aim: Vector2) -> Dictionary
```
Never store player level/augments in a `GameManager.player_level` singleton. Store by stable per-run PlayerState ID; solo uses same interfaces with local authoritative peer.

## I4. Example atomic EXP claim (pseudocode)
```gdscript
func try_claim_orb(player_id: int, orb_id: int) -> bool:
    if not multiplayer.is_server(): return false
    var p = players.get(player_id)
    var orb = orbs.get(orb_id)
    if p == null or orb == null or orb.claimed or not p.is_active(): return false
    if p.global_position.distance_to(orb.position) > p.pickup_radius: return false
    orb.claimed = true     # host main-thread decision, before emit
    grant_exp_to_player(player_id, orb.exp_amount)
    broadcast_orb_consumed(orb_id, player_id)
    return true
```
If orb claim relies on position snapshots, use authoritative server positions; do not trust client proximity messages.

## I5. Picker behavior — mandatory negative rules
- UI shows only local player's pending offer.
- No call to `Engine.time_scale`, `get_tree().paused`, physics process disable, enemy target filter, damage bypass, invulnerability mask or shield grant when opened/closed.
- Input may be shared: WASD still moves locally if player chooses to move; clicking a card uses mouse. Auto combat continues normally; no invented defensive auto-cast.
- Keep death overlay and picker priority consistent: on `DEAD/DOWNED`, hide picker and keep server queue for permitted revival; no auto-pick.
- Reevaluate offer before commit. Never trust client chosen augment rank.

## I6. Data migration
Current solo systems often assume `get_first_node_in_group('player')` or one global `current_player`; audit all skill, enemy targeting, EXP pickup, HUD, damage, level and boss references. Replace only necessary references with player IDs and query methods. Make no artistic/VFX edits. Carry `caster_id` and `owner_peer_id` through effects for damage attribution; use `caster_id` in authoritative events. Add smoke tests for solo to prevent regressions.

## I7. Universal Augment integration
Eligibility calculated per player's character/skills/capabilities. Generate offers host-side, store canonical options, choose only a offered option; modifier application uses shared `AugmentManager`. A split projectile spawning 3 projectiles should produce one cast event with correlated projectile IDs; do not run client independent proc rolls. Set per-cast deterministic seed for VFX only, server resolves gameplay procs. Preserve generation limits and dedup.

## I8. Menu/network loop
Do not let UI consume the simulation loop or drop packets. An inactive picker is not a pause mechanism. In initial MVP avoid storing detailed gameplay stats in per-frame reliable messages; only send necessary state deltas and event confirmations.
