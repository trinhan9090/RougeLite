# 07 — Locked Decisions, Defaults and Open Questions

## LOCKED (user-approved)
- Multiplayer 3–4 persons desired; implementation can support 1–4 total.
- EXP and character levels are **individual**, not pooled.
- Augment picking is **individual** and **does not pause** the run or any local player's gameplay.
- **No protection when selecting an Augment.** Even if the player dies mid-selection, damage and AI must continue normally.
- Game is Windows/Godot action roguelite using J/K/L/I, WASD, basic target-nearest, Auto/Manual skills, skill unlocks at personal levels 3/6/9/11, per-character Augments and shared gameplay components.

## Chosen architecture defaults (not specifically user-approved gameplay decisions)
- Listen-host ENet / UDP + join IP/port; max 4 peers total; no external backend.
- No friendly fire; same arena, shared enemies/boss/map, individual build.
- EXP-orb pickup belongs to one player, first server-validated claimant.
- Boss strictly spawns every 180 seconds of shared match simulation time, even if earlier boss is still alive. [LOCKED]
- Survival duration is primary score; levels/EXP individual. [LOCKED]
- One random map is selected/generated at run start and remains unchanged throughout the match. No map transition or ticket queue. [LOCKED v1.2]
- Teammate uses F to revive downed player; while reviving cannot basic attack or use skills, including offensive autocast. [LOCKED]
- Boss HP scale 1+0.55*(n-1) at spawn.
- Revive exists in multiplayer, with 4s/80px/30% HP defaults; picker hides on downed/death, queue persists for revive.
- No midrun join or host migration in MVP. Existing level-up pending queue remains until selected or run ends.
- Combat event authority host; clients predict owned motion and cosmetic start VFX, not damage.

## Questions to resolve before final gameplay balance (not blockers for testable network MVP)
1. **Who receives an EXP orb?** Current default first picker. Alternative: killer ownership, proximity shares, instanced orb for each player. Affects fairness in 4-person coop.
2. **Random map generation algorithm and template pool:** reuse project generator; validate deterministic result and traversable player/boss spawn points; avoid geometry desync.
3. **Revive tuning**: 4 seconds, 80px, 30% HP defaults; user locked key F and combat/skill suppression, not numeric parameters.
4. **Run ending:** all players dead, host death, or another condition? Recommended all unavailable players, if revive exists; otherwise agreed rules from solo.
5. **Disconnected player:** removes from boss target immediately, but roster slot reservation/reconnect deferred.
6. **EXP and level while dead:** default disabled until revived; preserve earned pending choices.
7. **Manual picker UI control:** mouse vs 1–3, Esc hide; ensure no special protections and movement remains possible.

## Change management
Every change to locked rules requires user confirmation and a signed decision record with date, reason, affected modules and backward-compatibility plan. Defaults may be tuned in resources after playtest but must be documented.
