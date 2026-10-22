# Multiplayer Test + Fix Report (2026-10-21)

## Summary

The reported error `Can't load the script "res://multiplayer/scenes/test_host.gd" as it
doesn't inherit from SceneTree or MainLoop` was real, but it was the smallest of several
blocking defects. Testing the multiplayer module end to end uncovered **8 defects**; all were
fixed and verified. Remaining limitations are documented under "Known gaps".

The whole host/join -> lobby -> match -> in-game flow now runs correctly between two real
Godot processes, and the match scene is fully playable (movement, skills, HUD, Esc pause/settings).

## How to run the tests

All tests are headless and use the project's convention (`extends SceneTree`).

```powershell
# Single-process module smoke test
.\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://multiplayer/scenes/test_host.gd

# Single-process gameplay wiring test (movement + Esc pause in the match scene)
.\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://multiplayer/scenes/test_combat_scene.gd

# Two-process network tests (start the host first, then the client)
.\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://multiplayer/scenes/test_host_client.gd -- --role=host --port=24682
.\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://multiplayer/scenes/test_host_client.gd -- --role=client --port=24682

# Two-process real UI flow (default port 24567; --port= overrides both sides)
.\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://multiplayer/scenes/test_session_flow.gd -- --role=host --port=24682
.\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://multiplayer/scenes/test_session_flow.gd -- --role=client --port=24682
```

Final results:

| Test | Checks | Failures | Exit |
|---|---|---|---|
| multiplayer_host (module smoke) | 10 | 0 | 0 |
| multiplayer_host (2-process network) | 17 | 0 | 0 |
| multiplayer_client (2-process network) | 10 | 0 | 0 |
| session_flow_host (2-process UI flow) | 16 | 0 | 0 |
| session_flow_client (2-process UI flow) | 12 | 0 | 0 |
| test_combat_scene (gameplay wiring) | 9 | 0 | 0 |
| tests/unit/test_content.gd (regression) | 31 | 0 | 0 |
| tests/integration/test_actors.gd (regression) | 5 | 0 | 0 |

## Defects found and fixed

### D0 - Match scene was a non-playable placeholder (no movement, no Esc)
After the network fixes, entering a match showed an empty field with a static label: the
`multiplayer_combat_run.gd` scene had no player actor, no camera follow, no combat systems and no
pause menu. Movement input was sent to the server but never applied to anything visible, and
`Esc` had no handler in the scene.

**Fix:** the multiplayer match scene now instantiates the real
`scenes/run/combat_run.tscn` (`CombatRunRoot`), so the standard gameplay stack runs inside the
multiplayer session: `PlayerActor` movement, skills, HUD, upgrades, camera, and the
`RunPresentation` pause/settings modal (`Esc`). Other peers are drawn as ghost actors whose
positions are replicated at 10 Hz.

`test_combat_scene.gd` verifies this headlessly: the player exists, `move_right` moves it, and a
synthetic Escape key press pauses the run and flips the run phase to `PAUSED`.
`test_session_flow.gd` additionally verifies ghost replication in both directions: each peer sees
the other player's ghost, and the host observes the client's ghost moving when the client holds
`move_right`.

Follow-up fix: the host used to spawn a ghost for **itself** (a blue box labelled `P1 astra` at the
world origin), because `player_joined_session` fires for the host's own registration before
`local_player_id` is known. Ghosts are now created lazily from position RPCs and are never created
for the local player id; the ghost name label was removed. The debug panel was moved to the
top-right so it no longer overlaps the run HUD/controls text.

### D1 - `test_host.gd` could never run (the reported error)
`multiplayer/scenes/test_host.gd` extended `Node`, but `--script` requires `SceneTree` or
`MainLoop`. The host test documented in `MULTIPLAYER_STATUS.md` was therefore never executed.

**Fix:** rewrote it as a `SceneTree` suite in the project's standard test style.

### D2 - Hosting and joining always failed ("peer already active")
Godot assigns an `OfflineMultiplayerPeer` at startup, and `multiplayer.has_multiplayer_peer()`
returns `true` for it. `NetworkManager.start_host()`/`join_host()` used that call as the
"session already active" guard, so **every** attempt to host or join returned
`ERR_ALREADY_IN_USE`. This is the defect that would make the MULTIPLAYER button appear broken.

Verified directly:

```
has_multiplayer_peer=true
peer_class=OfflineMultiplayerPeer
is_offline=true
```

**Fix:** `NetworkManager._has_network_peer()` treats an offline peer as "no session"; used by
`is_host()`, `is_client()`, `is_active()`, `get_peer_count()`, `start_host()` and `join_host()`.

### D3 - Stopping a session spammed errors every frame
`stop()` set `multiplayer.multiplayer_peer = null`, after which `SnapshotReplication._process`
called `multiplayer.get_unique_id()` and errored on every frame:
`ERROR: No multiplayer peer is assigned. Unable to get unique ID.`

**Fix:** `stop()` restores an `OfflineMultiplayerPeer` instead of `null`, and
`SnapshotReplication._process` guards on `has_multiplayer_peer()`.

### D4 - Solo host hung forever on "Start Match"
`MultiplayerCoordinator.start_match()` awaits `map_sync.all_clients_ready`, but with no clients
`MapSync.initialize_map_on_host()` emitted that signal *before* the await was registered. The
await then never resolved, so a solo host never entered the match. Log evidence:

```
MapSync: No clients connected, starting immediately
Session started - transitioning to IN_GAME     <- host: this line never appeared
```

**Fix:** emit `all_clients_ready.call_deferred()` so a caller that awaits immediately after
`initialize_map_on_host()` still observes it.

### D5 - Client input was rejected as "RPC to yourself"
`InputReplication.send_input_to_server()` only checked `has_multiplayer_peer()`. Without a real
session the offline peer reports unique id `1` (the host's id), so `rpc_id(1, ...)` targeted
itself: `ERROR: RPC '_receive_client_input' on yourself is not allowed by selected mode.`

**Fix:** bail out when the peer is offline or when `get_unique_id() == 1`.

### D6 - The combat scene did not parse / clients could not use it
`multiplayer_combat_run.gd` extended `Node` but called `get_global_mouse_position()` (a `Node2D`
method), so the script failed to load:
`Parse Error: Function "get_global_mouse_position()" not found in base self`. Entering the match
would fail. The scene also used input actions (`move_left`, `attack`, `skill_j`, `revive`) that
do not exist (`AppSettings` registers `move_up/down/left/right`, `basic_attack`, `active_1..4`),
and `MultiplayerGameBridge.is_multiplayer_session` was never set, so `process_local_input()`
dropped every frame. Clients also never registered with the host and never learned their player
id (`register_local_player()` returned `-1`, "TODO: Implement handshake protocol").

**Fix:**
- `multiplayer_combat_run.gd` now extends `Node2D`.
- Reads the real input actions; uses the `KEY_F` revive key.
- `MultiplayerGameBridge.is_multiplayer_session` is initialized on scene entry.
- `MultiplayerGameBridge.register_player_actor()` gained an explicit `is_local` flag, because a
  client cannot resolve its own peer id against the host-side roster.
- `MultiplayerCoordinator.register_local_player()` now sends a join request; the host replies with
  `_client_receive_join_accepted` and the new `local_player_registered` signal drives local actor
  spawning on both sides.
- Actors are spawned under `WorldContainer` for every player; `_update_debug_labels()` fills the
  existing debug panel (previously static placeholder text).

### D7 - Duplicate register/unregister noise
`register_player()` / `unregister_player()` overwrote state and logged on every repeat call
(the host registered the same player twice, and three "unregistered" lines appeared for one
disconnect).

**Fix:** idempotent in-place update, no-op when not present, and the combat scene delegates
authoritative-world unregistration to the coordinator (single owner).

## Known gaps (not fixed)

**Fully authoritative combat is not implemented.** Each peer runs its own `CombatRunRoot`
simulation. Players see each other move (ghost actors) and the shared match clock runs, but
enemies, projectiles, damage, XP and loot are still simulated locally per peer. `AuthoritativeWorld`
applies movement only as a velocity vector with a hard-coded `move_speed = 200.0`, and
`_handle_player_action()` is empty. Real shared combat needs server-side enemy simulation plus
snapshot replication.

**Late joiners only learn about existing players through position updates.** A client that joins
after the host is already in the match gets no `player_joined_session` event for the host; the
first ghost position RPC creates the host's ghost (initially with an empty character label).

## Notes

- `MultiplayerSessionFlow` hosts on `host_port` (default 24567), matching
  `NetworkManager.DEFAULT_PORT`. The `--port=` test argument now sets this value so host and
  client use the same port; the join address/port inputs still apply only to clients.
- Session timers use wall-clock time; the match clock advances only once per second via RPC.
- Logs for these runs are in `.local-data/mp_*.log`.
