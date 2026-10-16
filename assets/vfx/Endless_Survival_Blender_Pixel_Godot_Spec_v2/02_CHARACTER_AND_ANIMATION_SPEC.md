# 02 — CHARACTER & ANIMATION PRODUCTION SPEC
## 1. Single asset schema / rig strategy
- Source of truth: one **master Blender scene** per character, separate mesh objects for body, head, hair, coat/cloth, primary weapon(s), VFX emit sockets; source materials with character palettes, UV textures where needed. For 3D-render-to-2D, armature/constraints drive poses. Separate collection `CHARACTER`, `WEAPONS`, `RIG`, `CAMERAS`, `LIGHTS`, `FX_HELPERS`. Do NOT render HUD or scene background with sprite.
- Standard skeleton names if feasible: `root`, `pelvis`, `spine`, `chest`, `neck`, `head`, `upper_arm.L/R`, `forearm.L/R`, `hand.L/R`, `thigh.L/R`, `shin.L/R`, `foot.L/R`, `weapon_socket.L/R`; map names in exporter config when imported asset differs.
- Orient towards 2D camera via rotating model on world Z between directions while keeping camera fixed, not by rotating camera per frame (preserves consistent lighting); if this obscures important weapon silhouette, author view-specific poses rather than faking.
- Animation authored at 24 fps internally, sampled at 8–12 fps output for base characters; VFX often 12–18 fps and shader continuous. These are proposed starting values; record each animation in manifest and validate timing in-game.
- Root motion NOT applied by baked sprite playback; Godot CharacterBody2D controls gameplay movement. Attack direction driven by actual combat target/aim, never by pointer for locomotion orientation. Separate aim facing visual from movement facing if required by design.
- Track animation timeline: `windup`, `active`, `recovery`, impact frame, projectile muzzle/cast socket. **Gameplay skill/cooldown/CC timings remain authoritative from gameplay code**; timeline VFX must not silently alter hit registration.

## 2. Astra — male celestial mage
- Visual identity: adult male slender athletic, dark hair with cool blue highlights, high collar layered white/indigo robes, gold astrolabe accents, long staff with bright blue compass-star. Silhouette: tall staff/head gem distinguishable at 1× gameplay scale. Avoid exact copied champion motifs.
- Rig: staff held in lead hand + casting free hand, coat hem secondary motion, separate star catalyst socket at staff tip. Readable front/rear/left/right; do not mirror ornamental staff if engraving would be nonsensical.
- Motion: idle float breathing + orbiting star; run brisk short step with coat movement; basic cast 0.10–0.16 s gesture and 1 readable muzzle flash; J forward binding hand/staff thrust; K shield gesture and speed stance; L palm-down ground placement; I 0.35–0.50 s windup and powerful braced beam pose; hit flinch, death fade/fall.
- 4-direction target frames (proposed): idle 6 @8fps; run 8 @10fps; basic 5 @12fps; cast J 6 @12fps; K 6 @12fps; L 7 @12fps; I 10 @12fps; hit 3 @10fps; death 10 @10fps. This is roughly 244 directional source frames at demo settings; procedural exports may optimize duplicate sequences but no copied neighboring atlas tiles.
- Skills (actual gameplay IDs): basic Light Bolt; J Radiant Snare; K Prism Guard; L Solar Field; I Celestial Beam. Visually echo poster’s Star Binding/Astral Guard/Stellar Circle/Nova Alignment names only as internal **style cues**, not renames.

## 3. Vex — western fantasy ADC gunslinger
- Visual identity: original Black male cowboy/gunslinger, broad-brim hat, red scarf/poncho, warm brown duster, black leather, twin brass revolvers; *inspired by western dual-pistol fantasy, not a trace/copy of Lucian's costume or guns*. Strong left/right pistol profile and readable hat at small size.
- Rig: bilateral hand gun sockets, separate muzzle emitters, recoil bones, scarf/coat trailing rig. Both guns consistently visible in directional exports where feasible. Distinguish genuine movement afterimages from duplicate wrongly sliced frames.
- Motion: idle hat tilt + subtle gun holster; run lean forward; basic alternating muzzle L/R (both output from **single gameplay attack definition** as appropriate); J Quick Barrage volley; K Tactical Roll/dash silhouette and dust; L Piercing Round two-hand braced charged shot; I Bullet Storm sustained firing multiple aimed angles. Hit/death.
- Proposed frames each direction: idle 6 @8; run 8 @12; basic 6 @12; J 8 @12; K 8 @14; L 7 @12; I 12 @12; hit 3 @10; death 10 @10. Confirm direction-specific facing, muzzle coordinates and scarf layering.
- **Conflict warning**: concept has Skill1 Piercing Shot and Skill3 Ricochet; gameplay spec states J Quick Barrage and L Piercing Round. Never overwrite gameplay based on poster.

## 4. Boros — brutal greatsword Brute
- Visual identity: original battle-scarred muscular male mercenary, oversized rectangular greatsword, worn asymmetrical charcoal steel, tattered crimson cloth. Dark-fantasy weight and scale reminiscent of a greatsword archetype; **not an exact copy of Guts, the Dragonslayer or manga character outfit**.
- Rig: oversized sword attached to both hands by IK or constrained helper, dedicated sword root for anticipation/follow-through; heavy shoulder, slower torso and cloak follow-through. Sword may go behind player on north view to avoid absurd overlap; separate sword in composite layer if needed.
- Motion: idle planted stance, run heavy footfall + dust, basic deliberate short swing, J Ground Slam vertical impact with ground shockwave, K Iron Resolve braced shield posture, L Crushing Charge forward windup and trailing dust, I Titan's Fury enlarged silhouette/aura/shockwave. Hit/death.
- Proposed frames each direction: idle 6 @8; run 8 @10; basic 7 @12; J 9 @12; K 6 @10; L 8 @12; I 10 @12; hit 4 @10; death 11 @10.
- **Conflict warning**: poster has J Wide Cleave, K Ground Slam, L Berserk, I Oblivion Slash. These are *concept-only*. Gameplay follows J Ground Slam / K Iron Resolve / L Crushing Charge / I Titan's Fury.

## 5. Modeling approach and no-paid-asset contingency
- Start with primitive/procedural meshes for silhouette and cloth; prefer a licensed base humanoid topology **only if redistributable license verified**, scripted Blender fitting and skinning. Avoid relying on text-to-3D black-box cloud providers for '100%' autonomy. Asset creation quality is bottleneck; report when custom style-quality cannot be reached without manual art direction.
- Establish reusable base humanoid body rig and animation library across three characters. Exaggerate melee weapon motion; keep face simplified if frame resolution cannot carry painterly character portrait details. No automatic frame-by-frame AI image regeneration — violates identity consistency.
- Export source `.blend`, per-animation camera preview, transparent frame PNGs, shadow-only option, 4-dir contact sheet, gameplay-scale mockup and `character_visual_manifest.json`.

## 6. Character QA gates
PASS iff correct gender/style silhouette, visibly different class, weapon consistency, no drifting feet, no duplicate strips/overlap, correct transparent alpha, 4 directions, at least idle/run/basic+J/K/L/I cast VFX hooks, each can switch auto/manual without breaking animation and attack orientation. Human evaluates movement/looks; tools must not mark aesthetic approval automatically.
