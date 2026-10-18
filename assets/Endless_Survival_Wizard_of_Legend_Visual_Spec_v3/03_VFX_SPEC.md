# 03 — REUSABLE COMBAT VFX IN WIZARD-OF-LEGEND–INSPIRED PIXEL STYLE

## Global rule
VFX must reflect authoritative runtime events/geometries; never invent gameplay projectile, hit, root, shield, stun, dash or boss warning. VFX scene scripts cannot alter enemy HP, status duration or collision. This spec replaces v2 *appearance/production method*, not effects of the actual skills.

## Reusable vocabulary / modules
`PixelProjectile`, `PixelTrail`, `MuzzleFlash`, `SlashArc`, `GroundCrack`, `DustBurst`, `ScreenSpaceImpact`, `RootGlyph`, `ShieldRing`, `GroundRune`, `BeamCore`, `DashAfterimage`, `BuffAura`, `ImpactSpark`, `HitFlash`, `PixelParticles`. Each VFX definition: `id`, `visual_capabilities`, `palette`, `source_event`, `anchor/socket`, `shape_kind`, `geometry_binding`, `layer`, `frames/fps`, `particle_budget`, `lifetime`, `cancel_policy`, `pool_key`, `accessibility_fallback`.

## Timeline reference (illustrative; sync to actual runtime)
- Shoot: 1–2 frames muzzle → 2–4 frames trail/flight (actual travel duration) → 2–3 frames hit spark.
- Heavy slash: 2–3 anticipation → 2–4 sweep → 2–3 recovery, impact flash ≤2 game frames.
- Area/root/shield: one clear onset + repeatable small pulse while active + fade on **actual** state expiry.
- Ult: conspicuous short windup → bright dominant shape with outlined contour → hit flashes → 2–4 frame fade; no 80% screen wash for long.

## Character-by-skill authoritative matrix
| Actor | Action | Runtime | Visual layers | Color / notes |
|---|---|---|---|---|
| Astra | Basic | light_bolt | staff spark + compact bolt sprite + short point trail + impact glyph | cyan core / blue contour |
| Astra | J | radiant_snare | binding bolt + gold star glint + root glyph only on confirmed root | blue/gold, split only when real projectiles |
| Astra | K | prism_guard | crisp segmented shield ring + shield-hit sprite + light step traces | shield must vanish on actual expiry/break |
| Astra | L | solar_field | stenciled pixel ring with radial pulse, subtle tick bursts | radius & duration linked to effective area |
| Astra | I | celestial_beam | charge rune → inner white beam/blue pixel edge → small gold sparks → exit flare | width and direction exactly runtime geometry |
| Vex | Basic | dual_shot | per-gun orange flash + bullet tracer + hit spark + rare brass casing | use actual alternating gun sockets |
| Vex | J | quick_barrage | successive recoil flashes + tracer streams | one pair of visual events per real shot |
| Vex | K | tactical_roll | dust + 2–3 nearest-neighbor silhouette afterimages + speed lines | distance/trajectory follows dash |
| Vex | L | piercing_round | larger gold shot + sharp through-hit mini sparks | pierce hit count from gameplay; not arbitrary ricochet |
| Vex | I | bullet_storm | compact outward/aimed bursts, recoil rhythm, sparse impact spark | visual LOD for trails, never culled hits |
| Boros | Basic | heavy_strike | blade edge streak + 1–2 impact fragments + dust | geometry line/arc without fake projectile |
| Boros | J | ground_slam | descending blade accent → ground fissure/radial shockwave → block fragments | shockwave radius matches actual hit volume |
| Boros | K | iron_resolve | iron-red guard outline with flicker on block and break | status uptime exact |
| Boros | L | crushing_charge | scarf streak, foot dust and line afterimages, collision burst | only real path; no fake charge shadow |
| Boros | I | titans_fury | layered crimson steel aura, pulse with enhanced attacks | visual body scale does not replace collision logic |

## Augment interaction and variant specification
- `Projectile Split`: one **distinct pixel tracer per real projectile** + shared spawn flash budget. Geometry comes from spawned projectile directions. Do not fake with duplicated texture streaks. Applies only to `SPLITTABLE` runtime capabilities.
- `Pierce`: use per-confirmed-impact spark; no visual stop if bullet continues.
- `Echo Cast`: second VFX from real second cast, no double-flash for cosmetic echo.
- `AOE Expand`: ring and decal visually cover actual area; use scalable 9-patch/circle shader or deterministic nearest pixel resampling, not stretched blur.
- `Followup Dash` vs `Split` exclusive evolution for a specified skill is a gameplay-level conflict resolver concern, not global prohibition on all dashes + split. VFX renders selected evolution, never decides compatibility.
- `OnHit Explosion`: explosion starts on actual on-hit resolution and respects proc safety; visual-only flashes do not trigger combat.
- Hard budget: clamp decorative emission; projectiles/hitbox actors owned by combat must never be removed for FPS. Preserve readability of telegraphs.

## Godot node templates
`FxInstance(Node2D) -> Sprite2D/AnimatedSprite2D + GPUParticles2D(optional) + AnimationPlayer(optional)`. `VfxFactory.spawn(effect_id, VisualContext)` uses pooling and registers cleanup; `VisualContext` contains `cast_id`, `source_skill_id`, `owner_id`, effective radius/angle/beam width, hit-confirmed flag, world direction, secondary/proc generation.

## Quality gates
Screenshots at 1× with black/grey/forest arenas; 3-panel still of onset/active/fade; one video per Basic/J/K/L/I for all characters; crowded scene + low VFX setting. Failed if: effect suggests a hit but gameplay misses; hit happens outside claimed ring; split shows phantom bullets; ultimate completely conceals boss telegraph; art resembles a vector gradient blur rather than pixel animation.
