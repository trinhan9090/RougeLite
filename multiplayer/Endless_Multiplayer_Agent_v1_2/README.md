# Endless Survival — Multiplayer Agent Handoff v1.0

**Status:** IMPLEMENTATION SPEC / proposed demo defaults. **Scope:** Godot 4 GDScript, Windows, ENet UDP, LAN or VPN (Hamachi/Radmin), 1 host + up to 3 remote clients. Single-player must continue to work.

## LOCKED user requirements
- Each player has **independent EXP, character level, active skills, cooldowns, health, Augments and build**.
- Each level-up shows that player's own 1-of-3 valid core offers; **NO global or local simulation pause**.
- **NO protection of any kind while choosing Augments**: no invulnerability, damage reduction, freeze, enemy aggro suppression, automatic dodge/auto-defend, or safe zone. A player may be downed/killed while the picker is open.
- Host authoritative gameplay. Up to four total players. No Supabase, account system, or public matchmaking required. LAN/VPN IP join sufficient.
- Existing 3-character demo and subsequent character extensions retain combat and visual behavior. No screenshots/videos required for handoff; **text test reports only** per user preference from recent character integrations.

## Required reading order
1. `01_GAMEPLAY_COOP_RULES.md` — irreversible gameplay rules and death during choice
2. `02_NETWORK_ARCHITECTURE.md` — runtime authority and packet transport
3. `03_PROTOCOL_AND_STATE.md` — messages, validation, replication and timelines
4. `04_GODOT_IMPLEMENTATION.md` — component interfaces and GDScript examples
5. `05_TASKS_AND_TESTS.md` — stage gates, acceptance and measured metrics
6. `06_AGENT_OPERATING_RULES.md` — autonomy, prohibited edits, delivery
7. `07_DECISIONS_AND_OPEN_ITEMS.md` — decisions and optional defaults

## Compatibility and precedence
This spec supersedes earlier **multiplayer proposals** of shared EXP/level, global level-up pause, and protected Augment selection. Existing `CORE_ARCHITECTURE`, `GAMEPLAY_SPEC`, `AGENTS`, and the visual v3 spec retain precedence for all **non-network gameplay**. Where per-player progression conflicts with solo assumptions, this handoff wins for co-op only.

## Delivery
Create or adapt a Godot project with Host/Join UI, at least two simultaneous clients locally, then 4 peers over LAN/VPN; run automated/headless tests and report observed results, not promises. Do not claim tests passed without execution.

## v1.2 override (18 Oct 2026)
- Boss spawns every 180 seconds, regardless of active bosses. No boss activation from level.
- Primary score is shared match survival time; personal EXP/levels/augments unchanged.
- Each run starts on ONE host-selected random map. Boss kills NEVER cause a map transition in the multiplayer demo.
- A living player may hold F to revive a downed teammate; reviver cannot attack or cast during channel; remains vulnerable.
- Refer to `08_TIME_BOSS_SCORE_REVIVE_SPEC.md` for detailed authority, wire fields, state machines and QA.
