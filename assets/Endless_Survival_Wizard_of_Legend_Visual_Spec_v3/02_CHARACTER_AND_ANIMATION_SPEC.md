# 02 — CHARACTER ART, DIRECTIONS AND ANIMATION (v3.0)

## Character production rule
No compulsory full 3D hero modeling. Agent chooses reproducible 2D frame workflow (Pixelorama native or generator-produced layers + scripted pixel cleanup); Blender only where it improves repeatability for prop, cape/weapon motion or reference projection. Agent does **not** ask the user to draw or manually rig. If fully automated generation produces poor silhouette, submit failure + representative previews, retry with simpler geometry, not false pass.

## Shared source layout
`source/characters/<id>/` = layered editable source (when available); `generated/characters/<id>/<state>/<direction>/000.png`; `generated/characters/<id>/manifest.json`; optional `weapons/`; `generated/atlases/`. Every character derives `CharacterVisualProfile`, animation state enumerations and 4-direction selection. Prefer separated body + held equipment + VFX, but no body limb puppet animation unless test proves it looks like crisp pixel art.

## Astra — male celestial Mage
Silhouette: slim-athletic mage; navy coat with off-white panels, small gold stellar trim; dark hair; star staff distinct at 40px. Avoid rendering every ornate poster motif. Hue: cold blue / gold. Priority cues: staff tip, coat shape, readable cast pose. Basic wand tilt and blue bolt; J concentrated bind cast; K crossed-arm shield stance; L planting staff and ground circle; I 2–4 anticipation frames followed by beam recoil. Do not convert game into a light-element clone of another IP. Maintain all locked runtime skill IDs.

## Vex — cowboy dual-pistol ADC
Silhouette: broad cowboy brim, red scarf, two compact pistols, brown vest/coat; original visual cues rather than exact Lucian copy. Rapid alternated hand recoil; clear left/right gun ownership; K roll/short movement poses and afterimages; J rapid burst; L aim/stability single piercing shot; I continuous bullet storm. Do not depict a full Ricochet String as native L (poster differs from gameplay). Keep hat/scarf readable at 1×. Run cycle 8–10 frames; muzzle positions socket-bound to current facing.

## Boros — massive-sword Brute
Silhouette: broad armor shoulders + gigantic greatsword + crimson scarf and heavy boots; original grim mercenary, not a traced Guts sprite. Emphasize sword weight with anticipation, arc follow-through, long recovery and brief hit impact accent. J = `ground_slam` (not poster wide cleave); K = iron barrier state; L = crushing charge with trail; I = temporary Titan state (not poster finishing slash). When Titan changes drawn scale, effective collision still driven by runtime. Do not pivot giant sword freely around the character center without drawing overlap/occlusion and foot anchors correctly.

## Animation minimum for 3-character demo
| State | Directions | Target frames | Notes |
|---|---|---:|---|
| idle | 4 | 4–6 | readable breathing/blink; can reuse held pose |
| run | 4 | 6–8 | distinct feet offsets, bounce ≤2px typical |
| basic | 4 | 5–8 | windup/active/recovery; must match combat events |
| cast_J | 4 | 5–8 | shared pose where valid, distinct impact cue |
| cast_K | 4 | 4–8 | CC/shield/roll phase distinct |
| cast_L | 4 | 5–8 | placement/shoot/charge |
| cast_I | 4 | 6–10 | clearly stronger, but does not freeze world gratuitously |
| hit / death | 4 | 3–6 / 6–10 | death loops prohibited unless intended |

These are **initial target counts**; animation isn't approved merely for having enough frames. Animations must preserve logical foot anchor, no unintended pose swapping, no sprite artifacts.

## Animation states and integration
Priority: death > locked hit animation > skill cast > basic > movement > idle (unless source gameplay overrides interrupt/cancel). Render frame-only animation doesn't apply damage. Gameplay communicates `on_attack_windup`, `on_attack_active`, `on_skill_cast`, `on_skill_completed`, `on_damage_taken`, `on_death`. Visuals are event subscribers and may use authored timing markers only to synchronize visuals with already-authoritative timestamps.

## Agent-generated art instructions
1. Read same reference crop for portrait/directional examples; infer minimal visual motifs, not one-to-one image extraction.
2. Generate one static stance per direction at in-game size. Export a 4-up sheet. Ensure hat/staff/sword silhouette remains recognizable.
3. Generate run/attack states by controllable pose transforms or frame authoring; prohibit naive X-flip where asymmetric cape/gun/staff behavior breaks.
4. Pixel-clean images algorithmically: contour alias checks, fixed alpha edges, palette quantization, joint continuity. Render full timeline GIF/APNG preview; compare apparent height and sprite origin.
5. Reject animation with duplicated unchanged frames across attack windup/impact, implausible weapon teleport or clipping, excessive camera-relative shifts, palette flicker.
6. Import tested images through versioned manifest. Leave prior images untouched until acceptance.

## Optional Blender adapter
When agent uses Blender, declare `source_method: blender` in manifest, supply `.blend` and scripts. Render with fixed orthographic camera and transparent RGBA, then nearest-downsample, palette-quantize and anti-alias cleanup. Keep camera/lighting consistent across frames. This is a **fallback** for difficult poses/props; it cannot become a hard dependency of every character. Check licensing of model/motions; no arbitrary auto-scraped proprietary meshes.
