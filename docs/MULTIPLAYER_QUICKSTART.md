# Multiplayer Module - Quick Start Guide

## Overview
This module adds optional 1-4 player LAN/VPN co-op to Endless Survival. Core principles:
- **Host authoritative**: Server validates all gameplay
- **Per-player progression**: Independent EXP, levels, augment offers
- **No protection during upgrades**: Full damage while choosing
- **Strict 180s boss spawns**: Exactly one boss every 3 minutes
- **Single map per run**: No map transitions
- **F-hold revive**: Teammates can revive downed players

## Quick Test (Localhost)

### 1. Start Host
```bash
# Launch Godot
godot

# In editor, run scene:
res://multiplayer/scenes/multiplayer_session_flow.tscn

# Click "HOST SESSION"
```

### 2. Join as Client
```bash
# Launch second Godot instance
godot

# Run same scene
# Enter address: 127.0.0.1
# Port: 24567
# Click "JOIN SESSION"
```

### 3. Verify Connection
- Host should show "1 player connected"
- Client should show "Connected to server"
- Both should see lobby screen

## LAN Test

### Host Machine
1. Find your local IP: `ipconfig` (Windows) or `ifconfig` (Linux/Mac)
2. Note IP address (e.g., 192.168.1.100)
3. Start host session (default port 24567)
4. Ensure firewall allows incoming connections on port 24567

### Client Machine(s)
1. Run multiplayer session flow
2. Enter host's LAN IP address
3. Use same port (24567)
4. Click JOIN

## VPN Test (ZeroTier/Tailscale/Hamachi)

### Setup
1. Install VPN software on all machines
2. Create/join same VPN network
3. Note VPN IP addresses (usually 10.x.x.x or 100.x.x.x)

### Connection
- Host uses VPN IP when starting host
- Clients enter host's VPN IP when joining
- Same port (24567)

## Architecture

### Authority Modules
All located in `multiplayer/net/`:
- `multiplayer_coordinator.gd` - Central coordinator (autoloaded)
- `network_manager.gd` - ENet lifecycle
- `session_manager.gd` - Player roster
- `authoritative_world.gd` - Gameplay simulation
- `exp_orb_authority.gd` - Orb claiming
- `augment_offer_authority.gd` - Upgrade offers
- `time_encounter_director.gd` - Boss spawns
- `match_clock_authority.gd` - Survival timer
- `revive_authority.gd` - Revive system
- `map_sync.gd` - Map initialization

### Integration
- `multiplayer/integration/multiplayer_game_bridge.gd` - Bridges to existing combat system
- `multiplayer/scenes/multiplayer_combat_run.gd` - MP combat scene

### UI
- `multiplayer/ui/host_join_menu.tscn` - Host/join interface
- `multiplayer/scenes/multiplayer_session_flow.tscn` - Full session flow

## Running Tests

### Unit Tests (requires GUT addon)
```bash
godot --headless --path . --script res://tests/multiplayer/run_multiplayer_tests.gd
```

### Manual Test Matrix
See `multiplayer/Endless_Multiplayer_Agent_v1_2/05_TASKS_AND_TESTS.md` for full test matrix (T01-T42).

Key tests:
- **T02**: 4 players connect successfully
- **T03**: 5th player rejected
- **T05**: Two players reach same orb → one claims
- **T09**: Damage continues during upgrade picker
- **T18**: Boss #2 spawns at 06:00 even if boss #1 alive
- **T27**: Boss spawns at exactly 03:00

## Configuration

### Port
Default: 24567
Change in `network_manager.gd`:
```gdscript
const DEFAULT_PORT: int = 24567
```

### Max Players
Default: 4
Change in `session_manager.gd`:
```gdscript
const MAX_PLAYERS: int = 4
```

### Boss Spawn Interval
Default: 180 seconds
Change in `time_encounter_director.gd`:
```gdscript
const BOSS_SPAWN_INTERVAL_SECONDS: float = 180.0
```

### Revive Settings
Default: 4s channel, 80px range, 30% HP restore
Change in `revive_authority.gd`:
```gdscript
const DEFAULT_REVIVE_DURATION: float = 4.0
const DEFAULT_REVIVE_RANGE: float = 80.0
const DEFAULT_REVIVE_HP_FRACTION: float = 0.3
```

## Integration with Existing Systems

### Required CombatRunRoot Modifications
1. Replace `player` singleton with player map keyed by `player_id`
2. Hook `_on_xp_orb_spawned` → `ExpOrbAuthority.spawn_orb()`
3. Hook `_on_level_up` → `AugmentOfferAuthority.queue_offer_for_player()`
4. Hook boss spawner → `TimeEncounterDirector` spawn events
5. Add match clock display from `MatchClockAuthority`

### Required PlayerActor Modifications
1. Add `player_id: int` property
2. Register with `AuthoritativeWorld` on spawn
3. Apply server position corrections from snapshots
4. Route input through `InputReplication` in MP mode

### Required SkillController Modifications
1. Block J/K/L/I during revive (`ReviveAuthority.is_reviving()`)
2. Validate casts with server authority in MP mode
3. Use `caster_id` for damage attribution

## Troubleshooting

### "Connection failed"
- Check firewall settings
- Verify port is not in use
- Ensure host IP is correct
- Try localhost (127.0.0.1) first

### "Session full"
- Max 4 players by design
- Check if 4 already connected

### "Map validation failed"
- Map seed mismatch between host/clients
- Ensure all machines use same Godot version
- Check content registry consistency

### Lag/stuttering
- Check network latency (see diagnostics overlay)
- Reduce enemy/projectile count
- Verify host machine performance

### Boss spawns missing
- Check `TimeEncounterDirector` tick count
- Verify `_physics_process` is running
- Ensure no pause/time_scale modifications

## Performance Targets (DEMO DEFAULT)

- **Target FPS**: 60 (host and clients)
- **Local LAN RTT**: < 15ms typical
- **Stress test**: 4 players + 100 enemies + 80 projectiles
- **Network bandwidth**: < 250 KiB/s per client downlink
- **Snapshot rate**: 20 Hz (50ms intervals)
- **Input rate**: 60 Hz (every physics frame)

## Known Limitations

### Not Implemented (MVP)
- Reconnect/rejoin after disconnect
- Spectator mode
- Voice chat
- Cloud dedicated servers
- Matchmaking
- Anti-cheat validation
- Asset streaming
- Mid-match join (must join before match starts)

### Explicit Design Choices
- No friendly fire (DEMO DEFAULT - can be enabled)
- First player in range claims orb (no shared XP)
- No global pause during upgrades
- No damage reduction during upgrades
- Single map per run (no transitions)
- Strict 180s boss schedule (no level-triggered spawns)

## Files Added (40 files)

### Core Modules (15):
- multiplayer/net/*.gd (all authority modules)

### Integration (2):
- multiplayer/integration/multiplayer_game_bridge.gd
- multiplayer/scenes/multiplayer_combat_run.gd

### UI (4):
- multiplayer/ui/host_join_menu.{gd,tscn}
- multiplayer/scenes/multiplayer_session_flow.{gd,tscn}
- multiplayer/scenes/multiplayer_combat_run.tscn

### Tests (7):
- tests/multiplayer/test_*.gd (6 test files)
- tests/multiplayer/run_multiplayer_tests.gd

### Documentation (2):
- docs/MULTIPLAYER_IMPLEMENTATION.md
- docs/MULTIPLAYER_QUICKSTART.md (this file)

### Specification (10):
- multiplayer/Endless_Multiplayer_Agent_v1_2/*.md

## Next Steps

1. **Test localhost**: Run host + client on same machine
2. **Test LAN**: Connect 2+ machines on same network
3. **Test VPN**: Connect over internet via VPN
4. **Integrate combat**: Wire CombatRunRoot to MultiplayerGameBridge
5. **Profile performance**: Measure under 4-player load
6. **Manual QA**: Execute test matrix T01-T42

## Support

For issues or questions:
1. Check `multiplayer/Endless_Multiplayer_Agent_v1_2/` specification docs
2. Review `docs/MULTIPLAYER_IMPLEMENTATION.md` for technical details
3. Examine test files in `tests/multiplayer/` for usage examples
4. Check `multiplayer/net/` module source for implementation

## Status

**Module**: Complete (MP0-MP6)  
**Tests**: Unit tests written, integration pending  
**Integration**: Bridge created, CombatRunRoot wiring pending  
**Documentation**: Complete  
**User Acceptance**: Pending manual testing
