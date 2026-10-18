# Cast origin and opt-in ground targeting

Status: Approved by explicit user instruction2026-10-17.

User requests shots from weapon/hands/body center and Astra L placed on the
nearest enemy, falling back to facing at maximum range. Add a loadout-owned
cast_origin_offset copied into Actor runtime, resolved by CombatService with
a wall sweep. Actual projectiles, prediction, beam hit geometry, beam burn
origin and VFX use that same resolved point. Existing actors default to zero.
Astra pixel body uses a centered hand/torso point12px above grounded feet.

TargetingDefinition gains an opt-in prefer_nearest_with_facing_fallback flag.
Only Astra L enables it. Nearest eligible target within cast range wins in both
modes; otherwise cast at max range along facing, including Auto mode. Explicit
manual direction for other skills remains unchanged. No character-ID branches,
shared-resource mutation, new singleton or modifier-order changes.

Ranges/cooldowns/damage/collider sizes and projectile/proc budgets stay unchanged.
Tests cover friendly/dead/out-of-range filtering, Auto/Manual empty fallback,
projectile initial origin/prediction, actual beam hit and its visual origin.
