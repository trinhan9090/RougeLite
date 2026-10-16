# 03 — COMBAT VFX SPECIFICATION AND REUSABLE IMPLEMENTATION
## 1. First principle
Gameplay determines damage, targeting, shapes, hit timing, status, augment eligibility. VFX **subscribes to events** and reads resolved visual geometry. No VFX script may directly apply damage or change gameplay cooldowns. Actual VFX in Godot should visually match the effective collision/hitbox radius and duration; beam widening augments update beam visuals through a common interface.

## 2. Standard effect anatomy
Every effect definition may have: `telegraph`, `cast_flash`, `primary_shape`, `secondary_arc_or_trail`, `impact_sparks`, `ground_decals`, `status_overlay`, `dissolve`; each with `visual_duration_ms`, `palette_id`, `z_layer`, `offset/socket`, `pool_key`, `max_instances`, `quality_level`. Limit bloom/glow to key accents. Distinct legible telegraphs for hostile attacks.

**Reusable effect primitives**:
- `projectile_tracer` (sprite+trail), `muzzle_flash`, `cone_slash`, `line_slash`, `radial_shockwave`, `circle_rune`, `line_beam`, `shield_dome`, `status_ring`, `dash_afterimage`, `impact_flash`, `sparks`, `floating_debris`, `aura`, `projectile_split_ghost`.
- GDScript `VfxFactory.spawn(effect_id, context)` instantiates a pooled `PackedScene`; effect never infers skill by character name. `VisualContext` holds source skill, owner, cast id, position, direction, target, shape width/radius, lifetime, element palette and is_primary flag. Trigger once per valid cast event; duplicates from passive follow gameplay budgets.
- Shader variants: palette swap, soft additive glow edge, UV scrolling core, dissolve, brief flash; no continuous full-screen blur. Use GPU particles only where target renderer supports them, build CPU or frame-based fallback if Web export later needs it.

## 3. VFX matrix — authoritative skills
| Character | Action | Reusable primitives | Layering / timeline | Augment linkage |
|---|---|---|---|---|
| Astra | Basic Light Bolt | muzzle_flash, projectile_tracer, impact_flash | star muzzle 40 ms; blue-white bolt and 2-frame impact | split multiplies projectiles only as actual spawned; trails follow every valid projectile |
| Astra | J Radiant Snare | projectile_tracer, circle_rune, status_ring | gold-blue sigil at source, traveling binding bolt, blue root ring on valid targets | Split/Pierce from effective projectile set; root ring per real status |
| Astra | K Prism Guard | shield_dome, aura, dash_afterimage | blue shield shell + gold star rim, subtle speed particles while buff active | radius/strength displayed via bounds/intensity, no misleading extra invulnerability |
| Astra | L Solar Field | circle_rune, ground_decals, sparks | placement ring, 0.25s pulse, sustained rune/tick, dissipate on expiration | size/duration follow effective area shape and rank |
| Astra | I Celestial Beam | line_beam, circle_rune, sparks, impact_flash | telegraph rune 0.35s, bright white core + cyan edge + gold streak, fade 0.2s | wider beam when width augmented, echo duplicates only when game actually casts again |
| Vex | Basic Dual Shot | muzzle_flash, projectile_tracer, impact_flash | alternating orange flashes, brass ejection optional, compact bullet streaks | multishot/split produce valid additional tracers |
| Vex | J Quick Barrage | muzzle_flash, projectile_tracer, impact_flash | rhythmic 4–7 flashes paced by actual fire events | count exactly actual shots; no fabricated visual-only bullets |
| Vex | K Tactical Roll | dash_afterimage, ground_decals, sparks | 2–3 afterimages + dust, short red scarf streak, landing puff | dash length scales trail duration/distance; no collision phantom |
| Vex | L Piercing Round | muzzle_flash, projectile_tracer, impact_flash | charged bright gold long tracer; spark on every pierced hit | pierce events generate separate sparks; Split only if effective capability allows |
| Vex | I Bullet Storm | muzzle_flash, projectile_tracer, sparks | rotating/aimed barrage by actual bullets, intensity ramps, cap visuals for performance | actual projectile count from skill rank and multishot; LOD removes decoration not hits |
| Boros | Basic Heavy Strike | line_slash, sparks, ground_decals | steel-white sword trail, weighty impact, dust + few crimson hit particles | arc width follows hitbox; never create fake projectile |
| Boros | J Ground Slam | radial_shockwave, ground_decals, floating_debris | heavy vertical blade swing, delayed expanding ring, debris + dust | ring max radius equals effective damage radius; second ring on rank4 only |
| Boros | K Iron Resolve | shield_dome, aura, status_ring | muted iron/red protective aura, flares when damage blocked | aura times reflect defense/shield runtime, not fixed duration |
| Boros | L Crushing Charge | dash_afterimage, ground_decals, sparks | low-profile red-grey trail and ground scrape, impact at collision | length matches real dash path; hazard trail exists only at rank4 |
| Boros | I Titan's Fury | aura, radial_shockwave, status_ring | crimson iron surge and stronger silhouette; pulses on enhanced basics at rank3 | render visual scale state separately from physics/hitbox; use runtime range |

## 4. Frame sequencing and polish
- **Basic**: 50–100ms windup accent, 100–160ms travel/active visual, 80–150ms impact fade (derived from runtime timings where necessary).
- **AOE / shield**: visible ring in actual world units; lifetime bound to gameplay buff/area; damage ticks use subtle pulse without blocking enemies.
- **Ultimate**: telegraph → anticipation → main core/surface/secondary particles → hit sparks/brief camera kick → decay. Visually dramatic but short enough not to conceal hazards. Presentation easing non-gameplay.
- **Hit feedback**: 1–2 frame white tint (not full-screen), selective shake with accessibility option and user setting, optional hitstop bound to animation/presentation without changing physics timers unless deliberately coded; distinct enemy hit and kill burst.

## 5. Universal augments / trigger safety
`on_projectile_spawned` VFX follows actual post-modifier spawned projectiles, never draws split ghosts without actual collision counterparts. `Projectile Split` on directional projectile abilities creates extra real projectile + visuals. `line_beam`, `cone_slash`, `circle_area` **do not** get standard projectile Split just for being directional. Capability system owns eligibility. Mutually exclusive skill evolution paths are resolved before VFX; after `Followup Dash` choice, `Split` no longer offered for that skill. VFX reads current skill runtime ability version; no gameplay-specific string switch per character.

## 6. Performance and safety budgets (DEMO DEFAULT)
- Soft cap: 350 simultaneous *decorative* particles visible, 150 projectile trails, 25 impact flashes at full intensity; distant effects degraded. Hard caps configurable based on device test. Actual gameplay projectiles/hitboxes are never culled by visual LOD.
- Pool temporary scenes; release once; cancel emission when scene/character freed; avoid signal handlers retaining dead references; effect must be pause-aware; correct z-order for world floor/behind char/in front of char/UI.
- Screenshots at 1× and 2×, at least one crowded high-level sequence; capture video for basic + J/K/L/I per character.
