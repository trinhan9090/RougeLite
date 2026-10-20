# 09 — Random Map Initialization and No-Transition Rules

## Player-facing behavior [LOCKED]
Each multiplayer match receives one randomly chosen/generated playable arena. No mid-match map change even after a boss dies. All 1–4 players occupy this map throughout the run. New random map only after returning to lobby/restarting with a fresh run ID.

## Host flow
1. Lobby complete → assign immutable run ID, map template ID, randomly drawn seed and stable generator version.
2. Generate obstacle layout, player spawn positions and safe boss spawn candidates; run navigability/collision checks. Retry alternate seed if invalid before match starts.
3. Canonicalize layout data (stable ordering, deterministic integer grid coordinates) and compute SHA-256 hash from serialized obstacle and collision data, not decorative details.
4. Send MAP_INIT to all clients. Clients generate locally only if identical generator and asset versions; compare hash. Fallback to canonical host layout or reject mismatch.
5. On all ready, transition to RUNNING, start the authoritative survival clock and boss scheduler. No further map commands in RUNNING.

## Invariants
- `run_id`, `map_id`, `map_seed`, collision hash are immutable after START.
- No boss death may call reset_map(), create_transition_ticket(), change_scene_to_new_map(), or clear_world_for_transition().
- Boss AI and spawn locations use host-authoritative topology and collision.
- Map obstacles/spawn points should not block all routes to teammates or force spawn inside obstacles.
- For performance, keep random generation out of per-frame loop, only run at match setup.

## Regression tests
- T_MAP_01: Run one starts different map seed to run two (confirm generator seed changes).
- T_MAP_02: All clients hash-match collision grid.
- T_MAP_03: Seed collisions/invalid spawn lead to regeneration before RUNNING only.
- T_MAP_04: First boss death does not change scene/map hash.
- T_MAP_05: Last boss death does not change scene/map hash.
- T_MAP_06: Two bosses overlap; defeating either does not alter geometry or timer.
- T_MAP_07: Replayed MAP_INIT during RUNNING is rejected; no reinitialization.
- T_MAP_08: 4-player join handshake, mismatched generator versions reject or canonical-sync safely.
