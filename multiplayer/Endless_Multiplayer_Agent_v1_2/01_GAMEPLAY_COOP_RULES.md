# 01 — Multiplayer Gameplay Contract

## G1. Run and players [LOCKED]
Each participant has a `player_id`, selected character, independent `PlayerProgression` (`level`, `current_exp`, `required_exp`), skills unlocked at their **own** levels 3/6/9/11, inventory of Augments with ranks, cooldowns, HP/shields and per-player control mode (Auto/Manual). Players occupy a single arena, fight the same enemy set and share boss/map phase. No friendly fire (DEMO DEFAULT).

Players can have different levels, even by large margins. Never derive one player's skill availability, XP threshold, upgrade offers, or enemy kill credit from another player's level. Player names must not serve as stable network identities.

## G2. EXP pickup [LOCKED: separate; DEMO DEFAULT: ownership policy]
World EXP orbs have server-assigned `orb_id`, amount, position, spawn tick and state. Default: first alive non-downed player within pickup range claims the orb; host decides atomically (no double claims). Magnet/pickup radius is **per player**; EXP is credited **only to the claiming player**. Orbs do not automatically distribute team-wide. A client may visually predict magnet motion but does not credit itself XP before authoritative confirmation. If two players overlap, host uses deterministic ordering (earliest authoritative pickup, then lower player_id on exact tie). Orb cleanup and claim broadcast once.

Alternative shared kill participation distribution is *not* selected. Changing policy affects balance and requires user approval. Record per-player XP and picked-up orb IDs for reconciliation.

## G3. Per-player level-up [LOCKED]
The host creates one pending offer set on every level-up for the owning player: 3 distinct eligible options unless fewer exist, in which case deterministic fallbacks such as repeatable stat cores fill the slots. Unlock skills for that player's levels 3/6/9/11 as specified by base gameplay (free skill unlock). Player can continue moving and fighting while picker is visible **if they choose to use available controls**; UI must not block other gameplay globally. Switching input focus should not artificially halt the character's simulation.

**NO PROTECTION:** character retains exactly the same incoming damage, enemy aggro, collision, CC, environmental hazards and vulnerability while picker is open. Never implement shielding, iframe, aggro redirection, AI pause, slow motion or other mitigation based on `is_upgrade_menu_open` / `has_pending_offer`. Auto-attack and Auto-skill continue according to existing mode/cooldowns while alive, not as a special defensive perk. Manual skills only activate on actual input.

### Offer queue and simultaneous levels
Pending offers are ordered per player using `offer_seq`, immutable `offer_id`, `level_earned`, 3 signed/host-owned choices and `status`. If one orb grants multiple levels, create one offer per level, queue it, and display **only the head**; continue combat during every choice. XP can continue accumulating; no level cap imposed by pending choices. All queued offers survive nonfatal transitions and reconnection where player state is retained.

The server must recheck choice eligibility when received. Offer cards are a snapshot, but changing progression/skills may make a previously valid choice invalid. On invalid selection, reject and refresh that **same head offer** with three current valid options, retaining sequence, or provide explicit deterministic substitute; never silently apply an invalid Augment. No duplicate application.

## G4. Death/downed while choosing [LOCKED: no protection; DEMO DEFAULT resolution]
- Damage continues; death/downed processes normally and does not automatically award or apply an Augment.
- Picker closes visually upon `DOWNED` or `DEAD`; the **pending offer queue is preserved** in server state and displayed again on revive, with revalidation on choice.
- A downed player cannot spend offers or fire skills; no forced autopick, no healing or revival granted by opening a menu.
- If the run ends while someone has a pending offer, those offers are discarded with the run.
- Recommended downed/revive mechanic is OPTIONAL and must not be added unless already supported or user approves; if current solo system uses instant death, keep instant death initially. In either case no protective exceptions.

## G5. Clock-based boss encounters and survival scoring [LOCKED]
- Multiplayer uses **one host-authoritative match clock**. `elapsed_match_ticks` only advances while the match simulation runs. With 60 simulation ticks per second, boss cadence = `180 * tick_rate`. On a match at elapsed 03:00, 06:00, 09:00 etc, **spawn exactly one new boss** for each crossed three-minute boundary, even if earlier bosses are still alive. This is not a single-boss gate; never delay, cancel or merge spawns because another boss is active.
- Maintain `next_boss_sequence` and `last_processed_elapsed_tick` in authoritative run state. Boss ID = stable `(run_id, boss_sequence)`; deduplicate event delivery and spawn. Use a bounded catch-up loop for delayed frames so tick stalls do not skip a scheduled boss. A host freeze does not advance simulation time; communicate this in HUD and match results.
- **Score is team survival duration**, displayed `MM:SS`, frozen at authoritative GAME_OVER. Bosses killed and enemies killed are optional secondary statistics, not added to the primary score. Character EXP and levels remain individual and **never schedule boss spawns**.
- Difficulty scaling is based on shared elapsed match time and spawned boss sequence, not on highest player level (tuning values are DEMO DEFAULT). `boss_spawn_time_seconds = 180 * boss_sequence`.
- Strict cadence can cause several living bosses. Keep each instance's stable id, HP, AI state, aggro, cooldowns, summon ownership and death deduplication separate. Do not silently cap simultaneous bosses or replace the strict cadence with a boss gate. Performance improvements must not secretly change the rule.
- **Single map per run [LOCKED]:** host randomly selects or generates one map at match start. No map transition, no map tickets, and no map regeneration after boss death, regardless of how many bosses are alive.
- **Initial map handshake:** host selects `map_id`, `map_seed`, `generator_version` and collision/obstacle manifest or checksum; all clients validate the same geometry before entering RUNNING. Reject mismatch or supply authoritative map layout.
- Track `run_id`, initial map configuration, clock, `boss_spawn_sequence`, `active_boss_ids`, `defeated_boss_ids` and event watermarks for snapshots/reconnect. Map changes only on a **new run**. Clients never schedule bosses locally based on UI timers.

## G6. Player revive interaction [LOCKED behavior, DEMO DEFAULT tuning]
- A downed player can be revived by a living teammate who **holds F** in range. The user explicitly requires that while reviving, the reviver **cannot basic attack or cast J/K/L/I**. Autocast and passive offensive procs that require initiating new attacks are suppressed; existing authorized projectiles/DoTs may finish normally.
- Prototype defaults: 80 game pixels max distance, 4.0 seconds uninterrupted hold, 30% max HP upon success, no movement during channel. `revive_range`, `revive_duration`, `revive_hp_fraction` must be data parameters. Reviver remains vulnerable; taking damage alone does not automatically cancel unless interrupted by CC/knockback or other configured interrupt.
- Host checks downed target, distance, active reviver, continuous input, player ownership and interrupts each simulation step. Releasing F, moving out of range, interruption, target reviving or disconnect cancels. Multiple revivers may be disallowed by default; explicitly reject duplicate starts. `REVIVE_STARTED`, `REVIVE_PROGRESS`, `REVIVE_CANCELLED`, `PLAYER_REVIVED` use stable IDs and cannot be trusted if submitted as client success claims.
- Reviver remains susceptible to damage and boss attacks; no invulnerability for anyone. On success, restore normal attack/skill control. On downed state during Augment selection, close picker and retain server offers until revived; no automatic selection. If all players are downed and nobody can revive, authoritative game over freezes timer and score.
