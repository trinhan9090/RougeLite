# 03 — Art, animation, VFX, SFX production

## Visual target
Wizard-of-Legend-inspired **readability and speed**, original character design. Character approx 32–48 px body height at logical 640×360, 16×16 base map tiles, 4 directions minimum N/S/E/W; optionally 8 only after acceptance. Nearest filter + integer display scaling; VFX crisp hard-pixel edges, limited selective additive glow, not soft blurry green fog.

## Character silhouette
Green hood or metal crown, angular mask, dark gray graphite armor, vivid emerald channeling gauntlets, deep muted jade cloak. Unique visual features: asymmetric shoulder plate, green rune chest core, segmented armored fingertips. No copyrighted logo, exact mask, armor silhouette or name copied from Dr. Doom. Output original gameplay sprite frames.

## Palette draft (DEMO DEFAULT)
`#10171C` near-black shadow, `#22313B` armor, `#475A5D` steel midtone, `#1E6D4A` dark green, `#32C967` emerald, `#A3FFB2` luminous light green, `#F2FFE5` core highlight, `#B8A977` gold accent. Track palette modifications as data; no per-frame color drift.

## Animation matrix
| Clip | Directions | Goal | Timing target |
|---|---|---|---|
| idle | N,S,E,W | breathing + shoulder/hand pulse | 4–6 frames at 6fps |
| run | N,S,E,W | clear feet movement, cloak sway | 6–8 frames at 10fps |
| basic_cast | N,S,E,W | arm aim, recoil, release | 5–7 frames at 12fps |
| cast_J | N,S,E,W | charge/beam release | 6–8 frames at 12fps |
| cast_K | N,S,E,W | hand seal/wide gesture | 6–8 frames at 12fps |
| cast_L | N,S,E,W | shield activation/gauntlet raise | 5–7 frames at 10fps |
| cast_I | N,S,E,W | prefire+channel+recovery | 8–12 frames at 12fps |
| hit | N,S,E,W | short hit reaction | 3–4 frames at 12fps |
| death | N,S,E,W | collapse | 7–10 frames at 10fps |

Original M.U.G.E.N sprites are mostly horizontal fighting poses. **Do not fake top/down orientation by flipping lateral poses** and present it as production-ready. If only sideways assets are available, report `2_DIR_POC_ONLY`, produce 4-direction original fallback frames or run isolated side-view POC.

## VFX layering for each action
- **Basic**: cast flash (0.06 s), projectile core/green trail, contact sparks (0.10 s), optional tiny impact ring. Source Photon Shot candidate; projectile travel comes from game engine.
- **J**: charging sparks and converging arc lines (0.16 s), sharp neon-white beam core, emerald outline, sparse electrical streaks, hit glyph, dissipate. Beam width tracks hitbox when width augment changes.
- **K**: ground target ring (telegraph), vertical electric boundary, root rune overhead per target, expiration contraction, rank-4 final burst. Exclude hazardous floor telegraph color from friendly effects if co-op later.
- **L**: shell ring (front and back layers for depth), 2–4 discrete orbiting orbs, periodic contact pulse, shield-break shard flash, fading on expiry. Orb sprite positions driven by gameplay runtime, not prerecorded movement.
- **I**: 0.65-s telegraph wedge, 5/7/9 staggered rays, emission flash, per-hit white/green sparks, final rank-3 blast, visible fade-out; do not wash out enemies or UI.

## Audio mapping
For every move detect `PlaySnd` and build mapping from `.snd` group/index through decoded preview. Do NOT assert any source SFX identity until heard. Candidate audio classes: light magic shot, sustained beam hum, magical cage crackle, shield loop, ultimate charge/fire, hit/impact, voice. A new original free sound may be used when needed; mark original and source references in ledger.

## Pixel VFX quality rules
Maintain logical-pixel alignment and predictable anchor, VFX may be larger than sprite canvas, preserve per-animation origin offsets, no single image frame with adjacent atlas bleed. Every effect must have spawn/loop/stop/cleanup. Recolor based on LUT or gradient palette, not blind image-wide hue shift that turns highlights muddy.

## Source-to-final separation
`third_party_raw/` remains isolated and excluded from public release; `generated/previews` for raw preview; `game/assets/viridian/` only contains explicitly permitted assets or private-test flagged copies. Store per-resource `license_status`, `distribution_allowed`, `source_sha256`.
