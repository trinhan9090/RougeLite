# Training mode
Date:2026-10-17
Status:Approved scope by explicit user request

Separate TRAINING menu entry reuses selected hero, controllers, executors, renderer and keybindings. All four actives unlock locally; full HP and zero active cooldown are training-only runtime behavior. One stationary immortal boss takes real resolved hits but neither moves, attacks, dies nor grants rewards. PLAY keeps its existing progression, boss gates, HP/cooldowns and content.

Use a CombatRunRoot extension with a separate physics loop and open temple, a BossActor extension with no AI movement/attacks, and a Health extension that retains full current maximum. DamageResolver determines HP damage and killed from committed health state: standard Health remains equivalent, immortal training Health cannot emit false kill results/procs. This is the existing polymorphic commit boundary, no copied damage formula or definition mutation. Metrics show mitigated hit damage rather than claiming HP was removed from an immortal dummy.

Manual is immediate with zero active cooldown. Auto planner runs at a documented4Hz preview cadence to avoid spawning whole3-second barrages sixty times/sec; cooldown remains0, normal executor motion/shield/companion restrictions and global budgets still apply. Basic interval remains normal for animation timing. Rank1–4 selector clamps ultimate to3; hero/rank changes rebuild training state. Reset clears temporary effects/positions/counters. Pause/menu/retry reuse existing UX. No XP/mobs/boss waves in training; settings are not automatically changed on entry.

Tests cover four heroes, repeated skills, giant lethal hit/no death or kill event, damage measurement, stationary/no attacks, pause/retry/hero/rank/reset, menu launch and ordinary PLAY isolation. No QA media exports.

Latest user extension: HP and EXP bars display current/max numeric values (HP1 decimal, XP integer). Space adds a basic_attack command through the same AttackController and interval, without disabling normal PLAY auto basics. Training adds a checkbox to disable only automatic basics, for isolated Space testing. Input binding is an optional key in existing v1 settings, defaults to Space for legacy files and uses normal conflict validation/rebinding. Accepted positive enemy hits emit cosmetic damage_number payloads; a separate bounded128-label world layer follows targets and clears on retry/death/map changes, outside combat/VFX budgets. Numbers show post-mitigation damage, including immortal training hits; crits have a distinct color and !.
