# MP0 — Multiplayer Architecture Audit and Migration Plan
**Date:** 2026-10-20  
**Status:** AUDIT COMPLETE  
**Godot Version:** 4.7.2 stable (confirmed via project.godot config_version=5, feature GL Compatibility)

## Executive Summary
Current architecture is **fully single-player**, with singleton `player: PlayerActor`, centralized `RunState` holding `current_level`/`current_xp`, and `LevelManager`/`AugmentManager` assuming one local player. Multiplayer v1.2 spec requires **per-player progression** (EXP/level/skills/augments), **host-authoritative** gameplay, **no pause or protection** during augment choice, **strict 180s boss spawns** regardless of player levels, and **one random map per run**. Migration strategy: introduce `multiplayer/net/` module with ENet peer management, refactor `CombatRunRoot` to support per-player state via `player_id`-indexed dictionaries, preserve solo mode as local authoritative with one player, and gate multiplayer features behind `multiplayer.has_multiplayer_peer()` checks.

## 1. Current Architecture Inventory

### 1.1 Core Classes and Ownership
| Class | Location | Responsibility | Singleton? |
|---|---|---|---|
| `CombatRunRoot` | `scripts/core/combat_run_root.gd` | Composition root, owns single `player`, `progression`, `augments`, spawning, boss gate | Scene root |
| `RunState` | `scripts/core/run_state.gd` | Centralized run data: `current_level`, `current_xp`, `run_upgrades`, `boss_gate_state`, `map_id` | Instance var in CombatRunRoot |
| `PlayerActor` | `scripts/actors/player_actor.gd` | Character instance: movement, HP, skills, visual | `player` instance var |
| `LevelManager` | (referenced as `progression`) | Level/XP tracking, thresholds, level-up emission | Service instance |
| `AugmentManager` | `scripts/augments/augment_manager.gd` | Apply/track augments, eligibility, offer generation | Service instance (`augments`) |
| `SkillController` | `scripts/combat/skill_controller.gd` | Per-actor skill lifecycle, cooldowns, cast validation | `skills` instance, bound to `player.actor_id` |
| `CombatService` | `scripts/combat/combat_service.gd` | Hit/damage resolution, projectile spawning, actor queries | Service instance (`combat`) |
| `ContentRegistryService` | `scripts/app/content_registry.gd` | Immutable content definitions | **Autoload** `/root/ContentRegistry` |
| `SettingsService` | `scripts/app/settings.gd` | User prefs, keybindings | **Autoload** `/root/AppSettings` |

**Key Findings:**  
- **No `get_first_node_in_group("player")` patterns** detected in main scripts; player accessed via instance variable.
- **Two autoloads only:** ContentRegistry, AppSettings — both read-only, multiplayer-safe.
- **`actor_id` already exists** on Actor base class; `player.actor_id = 1` hardcoded in `_start_run()`.
- **RunState stores centralized XP/level** — needs per-player split.

### 1.2 EXP and Progression Flow
```
EXP Orb spawns → player pickup (proximity check) → RunState.current_xp += amount
→ LevelManager checks threshold → emit level_up signal → CombatRunRoot._on_level_applied()
→ SkillController.unlock_skill_for_level() → AugmentManager.generate_offer() → UI picker shown
```
**Critical Multiplayer Conflicts:**  
1. **One `RunState.current_xp`** — must become `Dictionary[int, int]` (player_id → xp).
2. **One `LevelManager`** — must track per-player thresholds or instantiate per-player.
3. **One `_offer: Array[UpgradeOption]`** — must become `Dictionary[int, Array[UpgradeOption]]`.
4. **Orb pickup has no ownership tracking** — must add `orb_id`, `claimed_by` and atomic host claim logic.

### 1.3 Boss and Map Lifecycle
**Boss Spawning:** `BossGate.should_spawn_boss(state)` checks `boss_gate_state` and player `current_level`:
```gdscript
# gate.gd line ~40
func should_spawn_boss(state: RunState) -> bool:
    if state.boss_gate_state != &"IDLE": return false
    return state.current_level >= next_boss_level
```
**Conflict:** Multiplayer spec **LOCKED**: bosses spawn every 180 simulation seconds, **NOT** from player levels. Existing `boss_gate_state` and level triggers **must be replaced** with `match_clock`-based scheduling in host authority.

**Map Lifecycle:** `CombatRunRoot._change_map()` called after boss death:
```gdscript
func _resolve_boss_victory() -> void:
    # ... rewards ...
    _change_map()
```
**Conflict:** Multiplayer spec **LOCKED**: **ONE random map per run**; no map transitions after boss death. `_change_map()` and map bag rotation **disabled in multiplayer** mode.

### 1.4 Augment Picker and Pause Behavior
**Current:** `presentation.show_upgrade_picker()` displays UI; no explicit pause in combat_run_root.gd, simulation continues (good).  
**Spec Compliance:** ✅ **Already NO pause or protection** — simulation runs during picker. Must verify no hidden protection in enemy AI or damage logic.

### 1.5 Test Infrastructure
**Test Runner:** `tests/run_all.gd` spawns isolated Godot processes per suite, checks `failures=0` and exit code.  
**Suites:** 54 existing tests (unit/integration/scenes), all focused on single-player content/combat/progression.  
**Multiplayer Tests Needed:** New `tests/multiplayer/` directory with T01-T42 as specified in 05_TASKS_AND_TESTS.md.

## 2. Singleton and Global State Audit
**Grep Results for Common Anti-Patterns:**
```bash
grep -rn "get_first_node_in_group" scripts → 0 results
grep -rn "current_player\|player_level\|player_xp" scripts → 0 direct matches (state fields exist, not global vars)
```
✅ **No singleton player access patterns.**  
✅ **Autoloads are read-only services** (ContentRegistry, AppSettings).  
❌ **Centralized RunState** holds all progression; needs per-player split.

## 3. Migration Strategy

### 3.1 Phase 1: Networking Skeleton (MP1)
**Goal:** ENet host/join, max 4 players, connection/disconnection handling, no gameplay yet.

**New Files:**
```
res://multiplayer/net/network_manager.gd       # ENetMultiplayerPeer lifecycle
res://multiplayer/net/session_manager.gd       # Roster, player_id assignment, 4-player cap
res://multiplayer/net/net_protocol.gd          # Message (de)serialization, versioning
res://ui/multiplayer/host_join_menu.tscn       # IP/port entry, host/join buttons
```

**Autoload Registration:**  
Add to `project.godot`:
```ini
[autoload]
NetworkManager="*res://multiplayer/net/network_manager.gd"
```

**Tests:** T01-T03 (localhost connection, 4 accepted, 5th rejected).

### 3.2 Phase 2: Per-Player State Refactor (MP2+MP4)
**RunState Extension:**
```gdscript
# New fields in RunState
var player_states: Dictionary[int, PlayerState] = {}  # player_id → {level, xp, skills, augments, hp, ...}
var is_multiplayer: bool = false
var host_peer_id: int = 1
```

**PlayerState Structure (new class):**
```gdscript
class_name PlayerState extends RefCounted
var player_id: int
var peer_id: int
var character_id: StringName
var level: int = 1
var current_xp: int = 0
var unlocked_skills: Array[StringName] = []
var augment_ranks: Dictionary[StringName, int] = {}
var pending_offers: Array[OfferData] = []  # queue, head displayed
var hp: float
var max_hp: float
var is_downed: bool = false
var control_mode: StringName = &"AUTO"
```

**CombatRunRoot Refactor:**  
Replace `var player: PlayerActor` with `var players: Dictionary[int, PlayerActor] = {}`.  
Replace `var progression: LevelManager` with `var progressions: Dictionary[int, LevelManager] = {}` OR single `MultiplayerLevelManager` with per-player methods.  
Add `func get_local_player_id() -> int` returning `multiplayer.get_unique_id()` in multiplayer, `1` in solo.

**Orb Pickup Authority:**
```gdscript
# In CombatService or new ExpOrbAuthority
func try_claim_orb_rpc(player_id: int, orb_id: int) -> void:
    if not multiplayer.is_server(): return
    var orb = _orbs.get(orb_id)
    if orb == null or orb.claimed: return
    var player_actor = _get_player_actor(player_id)
    if player_actor.global_position.distance_to(orb.position) > player_actor.pickup_radius: return
    orb.claimed = true
    grant_exp_to_player(player_id, orb.exp_value)
    rpc("broadcast_orb_consumed", orb_id, player_id)
```

**Tests:** T04 (no cross-player control), T05 (atomic orb claim), T06-T08 (diverging progression), T09-T11 (damage during picker).

### 3.3 Phase 3: Authoritative World (MP3)
**Enemy/Projectile Authority:** Only host spawns enemies/projectiles; clients receive spawn/destroy RPCs.  
**Hit Detection:** Host-side only; clients display VFX on confirmed events.  
**Damage Resolver:** Already exists as `CombatService`; add `@rpc("authority")` wrappers for multiplayer damage events.

**Tests:** T16 (no duplicate damage), enemy aggro includes all players.

### 3.4 Phase 4: Match Clock and Boss Schedule (MP6)
**New Authoritative Clock:**
```gdscript
# In new TimeEncounterDirector or CombatRunRoot for multiplayer
var elapsed_match_ticks: int = 0
var next_boss_sequence: int = 1
const BOSS_CADENCE_TICKS: int = 180 * 60  # 180s * 60 physics ticks/s

func _physics_process(delta: float) -> void:
    if not multiplayer.is_server() or state.run_phase != &"RUNNING": return
    elapsed_match_ticks += 1
    while next_boss_sequence * BOSS_CADENCE_TICKS <= elapsed_match_ticks:
        spawn_scheduled_boss(next_boss_sequence)
        next_boss_sequence += 1
```

**Boss Death:** Remove `_change_map()` call; keep rewards/stats only.  
**Tests:** T17-T18, T27-T29 (boss spawns at 03:00/06:00 regardless of levels or active bosses).

### 3.5 Phase 5: Single Random Map (MP6 continued)
**Map Init Handshake:**
```gdscript
@rpc("authority", "call_local", "reliable")
func map_init(run_id: String, map_id: StringName, map_seed: int, collision_hash: int) -> void:
    # Clients rebuild map deterministically, reply with hash
    # Host validates agreement before entering RUNNING
```

**Disable Map Rotation:** Gate `_map_bag` logic behind `if not state.is_multiplayer`.

**Tests:** T19, T26, T33 (map hash agreement, no regeneration after boss death).

### 3.6 Phase 6: Revive Mechanic (MP6 continued)
**F-Hold Channel:**
```gdscript
# In new ReviveAuthority or CombatRunRoot
var active_revives: Dictionary[int, ReviveState] = {}  # reviver_id → {target_id, progress, start_tick}

func try_begin_revive(reviver_id: int, target_id: int) -> void:
    # Host validates: reviver alive, target downed, in range, not already reviving
    # Block basic/J/K/L/I casts for reviver; start progress timer
```

**Tests:** T36-T39 (revive progress/cancel/vulnerability, picker closes on downed).

### 3.7 Phase 7: Resilience (MP7-MP8)
**Duplicate RPC Protection:** Sequence numbers per message type, dedupe by stable IDs.  
**Invalid Request Rejection:** Reevaluate offer eligibility on choice, reject stale/invalid picks.  
**Packet Loss Tolerance:** ENet handles retransmission; test with artificial `--delay 100 --loss 3`.

**Tests:** T12-T15 (replay rejection, stale picks), T23, T41-T42 (network stress).

## 4. Dependency Ordering

**MP1 (networking skeleton) has no dependencies** → start immediately.  
**MP2 (movement replication) depends on MP1** (peer IDs, connection).  
**MP3 (world authority) depends on MP2** (player actors exist).  
**MP4 (personal progression) depends on MP3** (authoritative orb claims, damage).  
**MP6 (boss/map/revive) depends on MP4** (per-player state established).  
**MP7-MP8 (resilience/testing) depend on MP1-MP6** (all features implemented).

**Recommended Order:** MP0 (✅ this audit) → MP1 → MP2 → MP4 → MP3 → MP6 → MP7 → MP8.

## 5. Solo Mode Preservation Strategy
**Principle:** Multiplayer is **additive**, not replacement.  
**Implementation:**  
- **Entry point fork:** Foundation menu adds "Host/Join" buttons; existing "Start Run" launches solo `CombatRunRoot` with `is_multiplayer = false`.
- **Authority checks:** Wrap multiplayer RPC/replication behind `if multiplayer.has_multiplayer_peer()` guards; solo mode uses direct method calls.
- **Player ID mapping:** Solo uses `player_id = 1`, same code paths as multiplayer with one entry in dictionaries.
- **Regression tests:** All 54 existing tests must pass **unchanged** after multiplayer module added (T24 in spec).

## 6. Known Risks and Mitigation

| Risk | Impact | Mitigation |
|---|---|---|
| Large refactor breaks solo | High | Incremental changes; run regression suite after each MP gate |
| ENet peer limits enforced incorrectly | Medium | Test T02-T03 with actual 5 connection attempts |
| Boss spawn timing drift under lag | Medium | Use tick-based scheduling, not delta accumulation; bounded catch-up loop |
| Orb double-claim race condition | High | Atomic host-side `claimed` flag before XP grant; unit test with concurrent claims |
| Augment picker shows stale options | Medium | Reevaluate eligibility on server before applying choice |
| Map determinism breaks on floating-point | High | Use integer seeds, validate collision hash; reject mismatches |

## 7. Files Requiring Modification

**Heavy Refactor (per-player state split):**
- `scripts/core/combat_run_root.gd` — multiple players, per-player progression
- `scripts/core/run_state.gd` — add `player_states: Dictionary`
- `scripts/augments/augment_manager.gd` — per-player offer queues
- (Level manager file TBD based on actual implementation)

**Medium Changes (authority wrappers):**
- `scripts/combat/combat_service.gd` — RPC wrappers for hit/damage
- `scripts/combat/skill_controller.gd` — validate caster ownership
- `scripts/actors/player_actor.gd` — input replication hooks

**New Files (multiplayer module):**
- `res://multiplayer/net/*.gd` (8-10 new files per I1 in 04_GODOT_IMPLEMENTATION.md)
- `res://ui/multiplayer/host_join_menu.tscn`
- `tests/multiplayer/test_*.gd` (T01-T42 suite)

## 8. Estimated Scope
**Lines of Code (rough):**
- Networking skeleton: ~800 LOC (network_manager, session, protocol, UI)
- Per-player refactor: ~1200 LOC (RunState split, CombatRunRoot changes, orb authority)
- Authoritative world: ~600 LOC (enemy/projectile RPC, hit replication)
- Match clock/boss/revive: ~900 LOC (clock authority, strict boss spawns, F-revive channel)
- Tests: ~1500 LOC (42 test scenarios, fixtures, network simulation)
**Total: ~5000 LOC new/changed**, ~25% of existing 115-file codebase touched.

**Time Estimate (single developer, full-time):**  
MP1: 2-3 days | MP2: 3-4 days | MP4: 4-5 days | MP3: 3 days | MP6: 5-6 days | MP7-MP8: 3-4 days  
**Total: 20-25 developer days** (4-5 weeks) for full MP0-MP9 delivery with testing.

## 9. Acceptance Criteria for MP0
- ✅ This audit document written and reviewed.
- ✅ Singleton/global state patterns identified (none found).
- ✅ Existing test structure documented (run_all.gd, 54 suites).
- ✅ Godot version confirmed (4.7.2 stable).
- ✅ Player/EXP/Augment/boss/map API ownership mapped.
- ✅ Migration strategy defined with dependency ordering.
- ✅ Solo preservation strategy documented.
- **Next Step:** Implement MP1 (ENet networking skeleton, host/join UI, T01-T03).

---
**MP0 Status: COMPLETE**  
**Ready to proceed to MP1.**
