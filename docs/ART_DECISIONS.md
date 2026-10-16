# Art decisions - 2026-10-16

- ART-D01: Latest gameplay docs under docs/ supersede old handoff snapshots: Manual aim follows last movement/facing. No mouse aim reinstated.
- ART-D02: Retain tested 1152x720 canvas-items viewport and approximately72px visible hero height. Do not change physics distances/colliders to fit a640x360 demo default. Logical pixel assets remain128x128 and32x32 tiles; integer scaling is available at native viewport multiples, other sizes remain canvas-items scaling (limitation to inspect).
- ART-D03: New assets are reproducible, wholly original scripted pixel prototypes; concept references are inspected for palette/silhouette only and never sampled/cropped/traced. Vex becomes the requested western dual-pistol hero. Old user-supplied sprites are preserved but no longer used by the new profiles; unclear third-party rights remain quarantined.
- ART-D04: No paid tools or network runtime. Python3.12.14/Pillow12.3.0 are installed. jsonschema/pytest are absent; use a documented strict supported-keyword schema validator and stdlib unittest without installing a dependency. Do not claim complete generic JSON-Schema conformance.
- ART-D05: Presentation adapters/signals may expose existing confirmed cast/projectile/hit geometry but cannot add gameplay damage, projectiles, cooldowns, RNG draws or capabilities. Preserve DamageResolver and augment ordering. Cosmetic RNG independent.
- ART-D06: The existing ActorSprite adapter remains compatible for legacy fixtures; new VisualController/VisualProfile scene is selected by the cardinal metadata of optional art_frames. All renderer selection branches are about profile availability, never character identity inside combat/augment code.

Unresolved/owner review: procedural pixel style versus polished reference; four-direction motion smoothness; current viewport scale. These do not require owner manual production steps.
