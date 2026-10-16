# 01 — LOCKED ART DIRECTION AND PIXEL CONTRACT

## Goals
- Clear read at high enemy density (endless survival). The gameplay actor must be distinguishable against all maps and skill effects.
- 2D top-down **3/4**, no platformer side-view. Visible top of head/shoulders. Four *authored* base directions S/W/E/N, extensible to eight; mirroring allowed only when asymmetry and weapon-handedness remain acceptable. Do not pretend flipped pixels are independently authored.
- Premium-looking concept reference images are **mood boards**; do not crop mini characters from poster as production sprites. Poster text, backgrounds and UI borders are contamination. Derive a simplified silhouette and consistent pixels at gameplay resolution.
- The main hero should never disappear under particles, screen shake or overlapping enemies. Design VFX in four layers: ground decal (below actors), actor aura, attack effects, critical impact overlays.

## Demo defaults, overridable by data
| Attribute | Demo value | Validation |
|---|---|---|
| Logical viewport | 640×360 px | scale integers for 1280×720 and 1920×1080 letterbox where necessary |
| Ground cell | 32×32 px | atlas regions exact 32 grid |
| Character frame canvas | 128×128 RGBA px | same for all heroes; fixed origin, bottom-center feet anchor (64,108) |
| Hero visible height | Astra 58–65 px, Vex 58–65 px, Boros 67–75 px | proportional not identical body heights; collider dimensions independent |
| Facing | S, W, E, N | consistent order `south,east,north,west` is **not** implicit; manifest drives it |
| Animation | Idle 4f × 6fps; Run 8f × 10fps; Attack 6f × 12fps; Hit 3f × 10fps; Death 8f × 8fps | configurable per clip; stop on death |
| Rendering | Nearest texture filtering, mipmaps disabled for source sprites, pixel snapping tested | no smoothed/stretched pixels |
| Palette | Each hero ≤24 principal opaque colors excluding VFX gradients | hue family distinct; record RGB/hex |
| VFX draw order | ground < shadows < actors < weapons < beam impacts/UI | external visual scripts only |

## Palette identity (reference; colors editable without mechanics changes)
- Astra: midnight `#101A35`, electric blue `#417BEB`, soft blue `#8FCAFF`, ivory `#E9EEF9`, gold `#E7B96A`.
- Vex: dark leather `#31251F`, walnut `#734633`, cloth crimson `#B33A3A`, cartridge brass `#E0A44E`, spark `#FFDE8A`; skin handled respectfully and legibly with shade variation.
- Boros: charcoal `#242630`, steel `#69717C`, ice highlight `#B9D5E7`, cloth deep red `#8E2734`, worn leather `#664838`.
- Backgrounds muted/desaturated compared with heroes, no direct matching of Astra's blue blast or Vex's orange shot over bright matching map tiles.

## Camera and silhouette guardrails
- Actor origin is feet. Shadow ellipse directly at ground coordinates. Hands and weapons can extend past body but stay inside validated frame or separate sprite node with known bounds.
- Astra thin silhouette + tall staff / radial astrolabe; Vex cape + dual handgun posture + wide-brim hat; Boros massive shoulder/rectangular sword profile. These must read as distinct when silhouettes are shown without color.
- All attacks have a readable anticipation → active → recovery visually, but **damage comes from combat simulation**, never inferred from animation duration or particles.
- VFX cannot obscure enemy danger telegraphs. Reduce cosmetic particle count under load, never hide gameplay-critical hitbox telegraph.
- Give heroes **directional visual layers** and weapon attach sockets; a global rigid rotation of the entire pixel character is prohibited for locomotion.

## Source-of-truth precedence
Gameplay data (`SkillDefinition`, runtime status, targeting, cooldowns, augment capability) > visual spec timing/labels > concept panel art. For instance **Boros uses Ground Slam on J, Iron Resolve on K, Crushing Charge on L, Titan's Fury on I**. A different arrangement pictured in a concept poster is not authorized as gameplay redesign.

## Copyright / inspiration boundary
- Astra is an original male mage; Vex captures a western dual-gunslinger fantasy without reproducing Lucian likeness, outfit or skill visuals one-to-one; Boros conveys a heavy dark-fantasy sword mercenary without recreating Guts armor, face, sword silhouette, insignias, or exact costume. No proprietary franchise names/textures in production assets.
