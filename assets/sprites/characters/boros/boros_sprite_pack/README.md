# Boros sprites — visual prototype package

Contains 96 transparent PNG strips (12 animation names × 8 directions), each with **128×128** frame cells in a horizontal row. Each animation metadata record includes FPS, frame count, loop status and provisional impact-frame index.

**IMPORTANT:** This is an integration/test **prototype**, not final production-quality animation. Original image generation delivered atlases with inexact cell boundaries and inconsistent pose counts. Existing visual source animations were sampled and resized with nearest-neighbor. Missing actions (`iron_resolve`, `charge_start`, `charge_end`, `transform_start`, `transform_end`) are provisional pose reuse, **not new bespoke animation**. Therefore frame-timing, perfect anchors, smooth loops, accurate attack contact and consistency are not guaranteed; editing/redrawing by an animator is required before release.

The request inconsistently calls the weapon a greatsword and a hammer. This package uses the **greatsword**, as mandated in the character design and established artwork. Ground Slam is interpreted as a greatsword slam.

Godot 4: create SpriteFrames for AnimatedSprite2D; add frames from each horizontal strip with Hframes matching metadata and Vframes=1 (or slice into frames). Use nearest filtering. For sprite offset use `(0,-40)` as a STARTING ESTIMATE only, and manually calibrate feet alignment; do not assume `(64,104)` is visually exact in every pose.

Separate particles, foot shadow, shield, shockwaves and aura should be implemented in Godot, not these PNGs. At higher Ground Slam rank, a second wave is an independent gameplay event **0.4 s** after the first.
