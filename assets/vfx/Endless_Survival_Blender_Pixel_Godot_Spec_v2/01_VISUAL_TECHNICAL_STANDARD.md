# 01 — VISUAL TECHNICAL STANDARD
## 1. Art direction and honest target
Target: cohesive high-detail **pixel-art-inspired** dark fantasy look similar to reference concept sheets: Astra celestial blue/white/gold, Vex western gunslinger crimson/brass/amber, Boros dark steel/crimson/cold slash white. Concept posters use painterly pixel clusters and complex staged lighting; 1:1 reproduction within a small in-game sprite is impossible. Prioritize silhouette at actual camera scale, animation timing, hit readability, coherent palette, polished impact VFX and authored environments. Concept sheet thumbnails are not grid-perfect production frames.

**Do not claim 'pixel perfect'** merely because render was resized with nearest. Pixel art requires intentional clusters, consistent aliasing, controlled outlines/shading and no random checkerboard/noisy dither. Agent must demonstrate zoomed nearest-neighbor inspection and at-scale gameplay screenshots.

## 2. Camera, pixel density and resolution
- **DEMO PROPOSAL** logical target viewport: 640×360, reference window 1280×720 (2× integer); 16:9. Keep camera orthographic/fixed angle if Blender pre-renders direction sprites. Choose orthographic 3/4 from world top (proposed camera elevation 55° from horizontal, orthographic), target at feet/origin; use the *same transform* for all characters/props. Direction rotations at 0/90/180/270° for first pass; 8-direction later only after quality gate.
- **DEMO PROPOSAL** base environmental tile 32×32 pixels; feet-to-head visible sprite height target 72–96 logical pixels, visual bbox allowed to extend for weapon effects. **Canvas** 160×160 or 192×192 for characters (must not confuse frame canvas with apparent model height). Boros may need 192×192 due to sword reach; normalized displayed body height remains consistent with role (Boros ~1.12× Astra, Vex ~0.98× Astra, subject to user review). Use a shared *world pixels per meter* ratio for all three; never individually scale arbitrary frames to fill a canvas.
- Pixel 2D filtering `Nearest`, predictable centered/feet origins, integer-scale when applicable, disable animation interpolation for individual fixed-resolution frames. Avoid unintentional subpixel camera jitter. Snap appropriate character positions at final presentation stage; continuous physics uses floats, rendering may snap separately. Test camera movement diagonal and zoom.
- Different effects may use higher-resolution native particle textures than body sprites if visually coherent. Do not let glow wash out sprite edges.

## 3. Color and compositing
- Character **primary** palettes may share shadow neutrals but accent colors remain differentiated at gameplay scale.
- Astra: midnight blue/navy, pale cloth, cyan/azure aura, star-gold highlights. Vex: leather brown/black, red bandana, brass gunmetal, orange muzzle flash. Boros: near-black steel, iron greys, worn crimson cloak, icy white/blue steel sparks (not constant neon bloom).
- Render **linear-lit scene** to transparent RGBA, inspect alpha fringe on dark and light background; color transform for predictable gamma. Export unpremultiplied/straight alpha PNG where downstream expects straight; document settings. Never composite onto black while rendering transparent character assets.
- Use no more than illustrative 24–48 colors per character base sprite where possible, but **not a hard cap**; palette quantization can be reduced or skipped if it damages legibility. Never quantize alpha into jagged opaque halos.
- Prefer brightness priority: basic low, skill medium, ultimate high; scale particle density under 100+ enemies.

## 4. Asset units and anchors
- Each frame: RGBA, exact canvas W×H, anchor `feet` in local px and source model-space transform, all animation frames stable anchor. Transparent padding must be actually transparent, never neighboring frame bleed.
- Direction naming fixed: `south`, `west`, `east`, `north`, optionally `south_west`, `north_west`, `north_east`, `south_east`. No casual names such as left_1 in export.
- Animation IDs fixed: `idle`, `run`, `basic_attack`, `cast_j`, `cast_k`, `cast_l`, `cast_i`, `hit`, `death`; extra character action IDs allowed via declared manifest. Avoid 8 identical direction exports where appearance needs different silhouette/weapon layering.
- Color-coded silhouette proof required on dark forest, rocky dungeon and bright volcanic floor; avoid outlines that disappear in darkness.

## 5. LOD / scaling / performance
- 3D authoring output is **baked PNG**; game gameplay remains 2D `SpriteFrames` and `TileMapLayer` unless an approved change request. Blender is **not** a runtime dependency.
- Render effects by purpose: static sprite frames, Godot `Line2D`, shaders, `GPUParticles2D`, reusable effect scenes. Pool projectiles and particles; no node-per-particle at large counts. Tweak budgets via project settings and performance profiles.
- Suggested stress target (NOT guaranteed for all machines): 1280×720 window, 60 fps median with 100 simple enemies and 150 concurrent projectile/effect instances on defined test hardware; also measure 1% low, spikes, memory. Baseline machine/GPU required in report. Lower profile must preserve telegraphs and gameplay hitboxes.

## 6. Quality metrics
- Automated: valid PNG alpha, exact frame dims, no sprite bleeding, no truncated non-VFX sprite in collision-safe bounds, 4 directions present, fixed feet anchors, asset license metadata, deterministic render hashes under pinned tool versions, valid `SpriteFrames` and `.tscn` parse, no errors in Godot headless tests, VFX contains required telegraph and event hooks.
- Human review: design recognition, motion appeal, distinct combat feeling, VFX clarity in crowded scenes, concept resemblance measured visually at actual zoom. Make 1× and 4× nearest captures. Animation contact sheet alone is insufficient; generate video loops and 60-second full gameplay clip.
- Regressions: image difference threshold is **advisory** (shader/driver noise), not proof of artistic quality. Store golden images and manual approval notes.
