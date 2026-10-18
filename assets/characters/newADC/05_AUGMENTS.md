# 05 — AUGMENT MATRIX & EVOLUTION RULES

| Capability / Augment | Basic | J Burst | K Frag | L Mines | I Rocket |
|---|---|---|---|---|---|
| Projectile Split | YES | YES (projectile count budget) | NO default | NO | Optional only if missiles become split-compatible |
| Pierce | YES | YES | NO | NO | NO |
| Echo Cast | YES? on basic via proc-safe replay | YES | YES | YES if cap maintained | YES with cap |
| AOE Radius | NO | NO | YES | YES | YES |
| Explosion-on-Hit | conditional tag on bullet | conditional | no recursive | no recursive | no recursive |
| Crit | YES | YES | optional damage model | optional | optional |
| Cooldown reduction | attack interval modifier | YES | YES | YES | YES |
| Duration | NO | NO | burning field only | lifetime | cluster duration |

**Important:** `PROJECTILE` is not alone sufficient for `SPLITTABLE`, skill executor must implement multiple projectile emissions and event budgeting. Physical grenade and rocket can be declared `PROJECTILE` while lacking `SPLITTABLE` capability.

## Signature evolution (optional, not base skills)
- `Suppressive Funnel`: J tighter spread / more hits vs `Bullet Fan`: wider spread / crowd clear. Same evolution group, per-skill mutually exclusive.
- `Incendiary Payload`: K lasting burn vs `Disruptor Gas`: slow/weakening. Require only one payload mutation of K; source grenades/tear gas/motov support *candidate* visuals but not pre-verified effects.
- `Proximity Trigger`: L fast mines vs `Remote Detonation`: manual trigger; per-skill conflict.
- `Heavy Penetrator`: I straight anti-boss rocket vs `Cluster Barrage`: multi-explosion; per-skill conflict.

## Core safety
Universal stats cores unbounded via balance diminishing-returns as defined in repo, passive ranks 4–5 max. Filter by current runtime capabilities, prerequisites, conflicts, rank cap and player skill unlock. Revalidate selection transactionally. No character-name checks for generic cores; disallow circular on-hit/on-kill/explosion proc chains. Secondary effects have `generation_depth` and deterministic cap.
