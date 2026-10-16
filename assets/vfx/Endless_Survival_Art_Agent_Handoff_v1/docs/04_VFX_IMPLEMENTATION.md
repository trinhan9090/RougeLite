# 04 — COMPLETE ATTACK / J K L I VFX IMPLEMENTATION SPEC

## Non-negotiable runtime behavior
- All VFX are **cosmetic clients** of existing combat events. Damage, projectile count, collision, status and duration follow runtime/augments, not art storyboard.
- World effects anchored to `cast_id`, `skill_instance_id`, `effect_instance_id`; seeded animation variants are independent of combat RNG. Retire particles on pooled entity return; no stale trails or ghost copies.
- Each effect defined by an `EffectDefinition` (kind, palette, source atlas/shader, blend, lifetime, scale, layering, intensity/budget); an `EffectInstance` is per-cast and mutable. Skill visual events map `skill_id` to semantic effect templates, not a character-name `if/else` inside VFX engine.
- Geometry-driven: projectile split duplicates **one projectile VFX instance per actual projectile**; pierce generates multiple hit events; AOE scaling uses current runtime radius; beam width maps to actual hitbox width; Echo uses a distinct cast ID and reduced-intensity overlay.
- Always use a thin authoritative telegraph for boss dangerous areas. Cosmetic particles can be culled; telegraphs cannot.

## Basic visual timeline defaults (seconds; *art only*)
| Event | Duration | Notes |
|---|---:|---|
| Muzzle/staff spark | 0.06–0.12 | auto attack, sync projectile spawn |
| Projectile trail | life of actual projectile | persistent attachment, clean on collision |
| Hit spark | 0.10–0.18 | once per `OnHit`, sub-hit suppression budget |
| Melee blade trail | 0.12–0.22 | arc mesh/sprite around actual facing |
| Ground AOE warning | 0.15–0.30 when telegraphed | does not grant extra cast delay |
| Skill status indicator | duration from status component | root/shield/slow display follows status end |

## ASTRA: cool-blue + gold star motif
| Action | VFX trigger / shape | Gameplay linkage | Augment handling |
|---|---|---|---|
| Basic Light Bolt | staff flare → sharp blue/white star projectile + 1px blue trail → small starburst | homing projectile spawned/hit | one set per actual projectile; split/pierce uses standard projectile template |
| J Radiant Snare | gold ring appears at staff tip → blue lance/orb travels → bright binding ring/chain at struck enemy; root ring persists | projectile, `RootApplied`/`RootExpired` | split duplicates real projectiles; trail color and root status same; per-cast target hit rule preserved |
| K Prism Guard | translucent blue bubble edge, inner faint compass ring, speeding star-tail under feet | shield amount+move buff intervals | shield strength maps ring thickness only, no extra shield value |
| L Solar Field | targeting ground reticle → circular 3-layer star diagram, pulse every authoritative damage tick | AOE center/radius/tick and duration | resizes to runtime diameter 160/200 etc; tick effect cosmetic |
| I Celestial Beam | 0.20s star alignment windup → **continuous wide straight beam** with white core, blue rim, gold particles → fading line | beam executor, one damage resolution per allowed hit | beam width/echo modifiers affect visuals; projectile split **not** supported |

## VEX: amber ballistic effects, dust and steel
| Action | VFX trigger / shape | Gameplay linkage | Augment handling |
|---|---|---|---|
| Basic Dual Shot | alternate pistols' small white-yellow muzzle flashes; brass-orange tracer; 2–4 px impact spark | real projectiles | more projectiles ≠ more simulated extra shots; render actual count |
| J Quick Barrage | staggered muzzle flashes tied to burst shot times, short hot tracer streaks | burst 4–7 real shots according to rank | split on each eligible projectile with cap and dim secondary trails |
| K Tactical Roll | low white dust crescent and 2 transparent silhouettes in movement direction | dash state/path | no hit VFX if dash does not deal damage |
| L Piercing Round | braced recoil, narrow white-hot orange rail/tracer crossing targets, small exit spark | piercing projectile collision chain | each real pierce hit creates bounded spark; mark (rank 4) indicated by small distinct ring |
| I Bullet Storm | repeating dual muzzle flashes, fan of *actual* shots with short streaks; subtle recoil | repeated timed shots over 3s | bounce visual only for actual bounce modifier/augment; never draw invented ricochet |

## BOROS: steel-white impact, red power aura
| Action | VFX trigger / shape | Gameplay linkage | Augment handling |
|---|---|---|---|
| Basic Heavy Strike | heavy short steel-white slash arc following blade + small debris on hit | melee arc hit | shape enlarges only when attack range modifier truly changes |
| J Ground Slam | sword strikes ground → radial cracks/shock ring + dust/debris plume | circle radius/rank and optional delayed second ring | NOT projectile split eligible; second ring VFX only if rank creates it |
| K Iron Resolve | steel-tinted shield rim + darker shoulder glint; blocked-hit sparks and small outward reflect spark | shield, damage reduction, reflect events | no generic blue wizard bubble; reflects only real reflected damage |
| L Crushing Charge | low dust streak aligned to actual dash route; front-edge impact star; optional lingering line | dash path, hit, stun/trail rank | follows physics-authoritative path, stops at collision, trail only rank 4 |
| I Titan's Fury | dark crimson ring expanding from feet; armor flare, 1px white edge, red wisps; long buff-status pulse | temporary stat buff and duration, HP changes from gameplay | resize body visual conservatively without changing collision; attack pulse appears only rank 3 |

## VFX generic execution choices (Godot)
- `Line2D` for aiming/tracer, but pixel-aligned thickness at logical resolution; pre-baked tiny PNG for hit sparks/impact, `Polygon2D`/shader for cones and beams, `GPUParticles2D` optionally for cosmetic debris with CPU fallback if Web export requires it.
- Disable filtering on pixel textures, keep light-bloom restrained; snap sample positions where visually safe but do not quantize physics trajectories.
- VFX layer order: decal(-20), hero(-5 to 5), projectile(10), impact(20), warning UI(30); no global CanvasLayer that obscures HUD.
- Runtime pooled emitters must reset animation time, shader params, particles, alpha, owner, previous position and lineage before reuse.

## Effect event envelope (recommendation)
```gdscript
# VisualEventData extends RefCounted
var cast_id: int
var effect_id: int
var skill_id: StringName
var source_actor_id: int
var target_actor_id: int
var origin: Vector2
var direction: Vector2
var world_radius: float
var world_width: float
var duration: float
var secondary: bool
var visual_seed: int
```
Do not introduce new gameplay calculations while building this DTO; adapt to existing CombatContext/HitEvent contracts.

## Overdraw/performance budgets (DEMO DEFAULT)
- Max visible hero-owned cosmetic projectile trails: 120; lower priority/smaller alpha beyond limit, but *actual attacks remain*. Max 80 burst impacts visible simultaneously; 2D particles 400 total max; keep 95p frame time target under 16.7ms at 60fps on test PC if feasible; record device/setup and do not claim universal performance.
- Aggressive combat test: Astra Split+Echo; Vex Barrage+Split+Pierce; Boros Ground Slam with second ring and Titan's Fury. Every modifier must be reflected visually without doubling damage accidentally.
