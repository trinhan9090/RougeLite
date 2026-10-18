# 01 — VISUAL TECHNICAL STANDARD (v3.0)

## Artistic goal / deliberate non-goal
Reproduce the **readability, punchy timing, restrained arena, and layered high-contrast skill language** of premium top-down action pixel art. Do NOT attempt an exact clone of Wizard of Legend; characters, sprites, tile design, icons, font and sound must be original or properly licensed. The old high-detail character posters serve as **identity refs**, not pixel density targets. The gameplay camera decides detail.

## Source-of-truth hierarchy
`locked gameplay` > `runtime shapes/events` > `visual config` > `concept poster` > `ad-hoc artistic preferences`. VFX is event-driven; hitboxes do not depend on image alpha. No visual edit modifies effective damage, cooldown, spawn patterns or projectile counts. Visual camera shake never moves gameplay collision roots.

## Locked-for-demo VISUAL DEFAULTS (change only by evidence and log)
| Item | Demo baseline | Validation |
|---|---|---|
| Coordinate setup | 2D, Y-sort by feet/ground, top-down 3/4 art | screenshots walking around pillars |
| Logical viewport | 640×360; compare integer 2× scaling | no pixel shimmer; no half-pixel jumps |
| Pixel height | 32–48 *opaque pixels* for human player body | 1×/2× screenshot with 20 enemies |
| Sprite canvases | 64×64 for most body anim; 96×96 if needed; VFX detached | fixed origin, alpha margin, never chop equipment |
| Tile grid | 16×16; prefabs assembled 2×2 or more | seam test and repeat audit |
| Directions | N, S, E, W; author distinct mirrored sides if required | weapon handedness tests |
| Basic FPS | idle 4–6 fps; walk/run 8–12 fps; attack 10–16 fps | timing at game speed and 0.5 speed |
| Character color | Astra blue/white/gold, Vex amber/red/brown, Boros charcoal/steel/crimson | unique identity under desaturation |
| Filtering | nearest 2D textures, pixel snapping/integer origin | recorded render settings |
| VFX style | sprite-frame silhouettes + bounded pixel particles + carefully limited glow | spell readable in 30-monster arena |
| Camera | mild optional shake, configurable 0–100% | no motion sickness forced, no UI jitter |

**Not authoritative gameplay numbers**: animation FPS and sprite sizes are art defaults. Retain platform/performance tests before accepting any boost in detail.

## Pixel-art integrity tests
- No smooth resampling of sprite source (`NEAREST` on scaling); don't use display blur to hide low resolution.
- Consistent outline width/style and light direction; no pseudo-pixel textures consisting of random subpixel gradients.
- Palette budgeting: individual character typically 12–24 core colors before glow; VFX may exceed it for controlled readability, but no arbitrary multi-hue noise.
- Shadows live below the character feet and remain within ground; avoid poster-style full-screen glowing bloom.
- Frame silhouette stays recognizably the same person across 4 directions; weapons are readable with and without glow; avoid clipping at animation extremes.
- Sprite frame anchor = shared feet coordinate. Preserve world scale and foot Y; do not auto-crop + center every frame. Transparent padding is valid.
- Shape clarity: AOE rings communicate radius; cone telegraph follows real cone; pierce trace matches real ray/projectile; incoming attacks have distinct danger colors.

## Visual hierarchy / crowded play
1. Enemy and player positions / telegraphs, 2. active projectile trajectories, 3. damage/readable hit feedback, 4. flourish/decorations. At 30 enemies and split augment active, player stays visible and enemy windups distinguishable. Provide accessibility toggles `screen_shake`, `vfx_intensity`, `flashing`, optional background contrast.

## Godot implementation notes
- Use `AnimatedSprite2D` + `SpriteFrames` for bodies, `AnimationPlayer` for weapon sockets/recoil/shadow/focus frames; optionally `AnimationTree` if movement blending materially helps. `VisualController` listens to gameplay events (movement, cast, hit). Character art nodes must not own collision or target selection.
- `CanvasItem.texture_filter = NEAREST` consistently; use per-project appropriate 2D snap flags and verify on actual engine version. Use a stable Y-sort hierarchy; don't mix screen-space and world-space glow accidentally.
- Prefer animated sprite VFX for clearly pixelated forms; add `GPUParticles2D` with integer pixel texture/nearest and screen-tested limits; shaders should not make sprites look like smooth vector UI. Use `CanvasModulate`/`PointLight2D` conservatively; test with renderer/browser target if applicable.
- Rendering backend/Web differences: record feature compatibility for selected Godot version; Windows native baseline is required. Don't assume glow support across renderer targets.

## Verification matrix
Capture: (a) 1× no VFX (b) 1× all moves (c) 2× scaled (d) grayscale/contrast (e) large mob (30+) (f) split/pierce/echo augment (g) disabled shake / reduced flashes. Compare before/after side by side. Asset checks alone do NOT prove motion quality.
