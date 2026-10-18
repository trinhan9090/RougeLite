# 08 — V2 → V3 VISUAL MIGRATION, OPEN ISSUES AND RISKS

## Binding changes
| Area | v2 | v3 |
|---|---|---|
| Character creation | Blender-first model/rig/render | frame-based original 2D pixel art first |
| Blender | default core dependency | OPTIONAL specialist asset/proxy/prop tool |
| Art target | poster-like very detailed pixel look | Wizard-of-Legend–inspired compact readable action pixel art |
| Sprite silhouette | relatively large, elaborate | 32–48px opaque body default, tested in gameplay |
| Animation | 3D rig and multi-view renders | 2D frame animations + weapon socket + selective secondary movement |
| VFX | cinematic/highly layered beams | punchy pixel shapes, measured particles/glow, readability first |
| Map | source 3D props preferred | tilemap 16px + curated pixel props; 3D optional |
| QA | general visual comparability | 1× crowded screenshots, timing, collision and augment truth |

## Preserved
Godot 4/GDScript; original 3 characters; class/skills from LOCKED gameplay; WASD and J/K/L/I remap; Auto/Manual; level gates; bosses every 10; skill ranks; capability-based universal augments; mutual exclusion rules; seed-based safe map placement; human-only visual review.

## Existing poster contradictions
Astra poster titles J/K/L/I vary from canonical IDs; Vex poster has piercing shot on J and ricochet L, which contradicts `quick_barrage` J and `piercing_round` L. Boros poster features wide cleave J, ground slam K, berserk L and slash I; canonical Boros uses ground slam J, iron resolve K, crushing charge L, Titan's Fury I. Agent MUST NOT adjust gameplay to make imagery match. Render visually appropriate existing canon skills and explicitly mark poster labels as *non-authoritative*.

## Risks / mitigation
1. **AI pixel image inconsistency:** frame character identity drift. Remedy fixed silhouettes/anchor/palette, animation contacts, reject frames, optional rig-assisted pose fallback.
2. **Overfitting marketing concept:** portrait quality misleading. Remedy native-zoom approval and 30 enemy stress test.
3. **Unlicensed Wizard of Legend materials:** no asset scraping/tracing; use own sprites and CC0/compatible assets with provenance.
4. **Unstable renderer pixel scaling:** nearest/integer scaling, no fractional zoom, inspect multiple display resolutions.
5. **VFX lies about collisions:** bind to runtime events/shapes, visual-to-hit validation screenshots.
6. **Agent breaking older work:** branch/versioned generated outputs, smoke test before merge, diff review.
7. **100% automation expectation:** pipeline can automate technical stages; final art fidelity is non-guaranteed and requires human review; report unsolved blockers.
8. **Old v2 file names in prompts:** v3 is the visual authority, v2 history only; governance remains canonical.

## Initial decision defaults to review
- 4 facing directions rather than 8; 16 px tile units; body 32–48 px; native 640×360; nearest; one Astra benchmark gate before Vex/Boros. If live repo is already artistically better, record evidence rather than blindly downgrading current art.

## Official tool entry points (check versions and actual licenses on installation)
- Godot: https://godotengine.org/ ; https://docs.godotengine.org/
- Pixelorama: https://pixelorama.org/
- LibreSprite: https://libresprite.github.io/
- Krita: https://krita.org/
- Blender (optional): https://www.blender.org/
- Kenney (licenses per pack): https://kenney.nl/assets
No claim is made that any particular pack was downloaded or licensing independently re-verified during this document update; the agent must check at acquisition.
