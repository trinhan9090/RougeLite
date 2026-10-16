# 02 — CHARACTER PRODUCTION SPEC: ASTRA / VEX / BOROS

## Standard character delivery per hero
- `source/` editable layered document where supported (Pixelorama `.pxo` / Krita `.kra`) **or** reproducible procedural art generator source code and seed.
- `frames/<animation>/<direction>/<000..>.png`: separate RGBA full-canvas images, exact same size and foot anchor. No atlas bleed or embedded captions.
- `weapons/` transparent weapon sprite(s); `portraits/` menu portrait; `manifest.json`; `license.txt`; `evidence/` contact sheets and animated GIF/APNG previews.
- Minimum 4 directions × Idle, Run, Attack; Hit and Death may use authored shared/limited directional variants at prototype stage **only if explicitly documented**. Skills can reuse Cast while VFX provide differentiation. Aim to author four-direction Hit/Death for final acceptance.
- Layers preferably `body_base`, `head`, `back_arm`, `front_arm`, `legs`, `coat_or_cape`, `weapon`, `shadow`, `emissive`. Flat body frames can replace skeletal cutout where they look better. Never turn decorative concept portraits into game assets.

## ASTRA — MALE MAGE / STELLAR CONTROL
**Appearance:** young adult slim-athletic male. Navy/ivory high-collared cloak, restrained gold trim, celestial compass focus at staff tip, short black-blue hair; three broad readable visual shapes: coat tail / staff head / circular star sigil. Four-direction sprite changes cloak occlusion and hand placement rather than rotating entire sprite 90°.
**Weapon:** staff/catalyst held to side, staff tip always visible, 1–2px clear rim light; no low-resolution ornate detail overload.
**Silhouette:** narrow chest and long vertical staff; no bulky armor overlap. Feet anchor `(64,108)`; body centered, staff extends sideways.
**Animation:** idle orbiting star at staff tip as separate effect; run cloak secondary bob; basic short staff wrist flick; J casting hand forward; K protected pose; L ground gesture; I 0.20s windup braced stance. In auto mode animation still signals skill use.
**VFX palette:** bright cyan-white core, medium blue outline, low-density gold rune. Impact readable on dark and pale backgrounds.
**Shots:** Basic Light Bolt; J Radiant Snare; K Prism Guard; L Solar Field; I Celestial Beam — see visual behaviors in `04_VFX_IMPLEMENTATION.md` and authoritative numerical behavior in earlier `02_GAMEPLAY_SPEC.md`.

## VEX — WESTERN DUAL-PISTOL GUNSLINGER / ADC
**Appearance:** original adult gunslinger; western duster/poncho, red scarf, dark leather vest, antique brass dual pistols; optional wide-brimmed hat only if four-way sprite visibility remains clean. Distinct from franchise references: original face/hair silhouette, original armor and ornament, original gun geometry.
**Readability:** both pistols independently identifiable at 128px canvas; left/right hands alternate subtle recoil. Cape/scarf drag one-to-two pixel during run; muzzle flashes separate from body texture.
**Animation:** idle gun-check; run forward-leaning; attack short alternating fire with two barrel sockets; J rapid shot burst; K dash body-lean and afterimage; L braced aimed piercing round; I stream of shots with repeated recoil — no full-screen sprite enlargement.
**VFX:** amber/gold tracers, metallic spark impacts, dusty sand-colored dash trail. Avoid red-orange similar to enemy health bars by adding white-yellow cores.
**Shots:** Basic Dual Shot; J Quick Barrage; K Tactical Roll; L Piercing Round; I Bullet Storm. Explicitly preserve **these** mappings; concept artwork may label a ricochet as skill 3 but earlier gameplay gives L pierce and ricochet only as ultimate rank/augment behavior.

## BOROS — GREAT-SWORD JUGGERNAUT / BRUTE
**Appearance:** original broad-shouldered, battle-scarred mercenary in patched dark steel shoulder plates, uneven leather straps, torn burgundy scarf. Massive two-handed sword with blade shape sufficiently distinct from any existing branded sword. Heavy gait, wide planted legs, obvious weight. Not a direct portrait of any fictional character.
**Visual scale:** 67–75 px visible tall; same **canvas size, feet baseline and world scale convention** as others; not same character height. Protect clearance around long sword with separate `WeaponPivot` layer outside body cell when needed.
**Animation:** slow windup / fast slash / heavy recovery; repeated sword swing sound/VFX triggered from combat event, not hardcoded frame; run slow upper-body sway; Hit subtle heavy recoil; Death heavy collapse.
**VFX:** pale steel-blue slash edge, stone/dust/debris for ground impact; shield overlays neutral steel; charge trails brown-white; titan buff uses deep red aura plus larger shadow / silhouette, not unchecked nearest-neighbor scale that clips collision.
**Shots:** Basic Heavy Strike; J Ground Slam; K Iron Resolve; L Crushing Charge; I Titan's Fury. The older concept sheet includes a sweeping J cone, Berserk L and sword-wave ultimate — these are **illustrative aesthetics only**. Gameplay follows authoritative prior spec until owner explicitly changes it.

## Character production constraints
1. Create vector/shape blockout or pixel forms from **a consistent geometry design** for all four directions.
2. Generate base frame via script or editable graphics software; capture silhouette sheet before detailing.
3. Draw/load separate weapon for clear hit trail; tune animation at intended game viewport and background.
4. Every frame visually retains identity (hat/scarf for Vex, staff/star for Astra, heavy shoulder/greatsword for Boros).
5. Keep essential pixel colors stable across all frames, avoid AI drift changing clothing/hands/sword.
6. No character name dependence in `VisualController`; use `VisualProfile` / `AnimationManifest` mapping to generic signals.
7. Produce `contact_sheet.png` for every hero (all animation frames on neutral matte and sample map), `4way_preview.gif` and 10-second in-game video if capture tool available.
