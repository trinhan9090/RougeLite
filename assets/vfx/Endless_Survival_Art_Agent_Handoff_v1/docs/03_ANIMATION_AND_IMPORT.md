# 03 — DETERMINISTIC PIXEL ANIMATION / IMPORT CONTRACT

## Preferred pipeline
Concept reference → geometry/silhouette specification → editable source or procedural pixel drawing → **separate frame PNGs** → deterministic normalization/validation → Godot `SpriteFrames` generation → scene sockets + `AnimationPlayer` for weapons → replayable screenshot review. Sprite sheets are **optional build artifact only**, never the single source of truth.

## Animation naming and axes
`idle`, `run`, `basic`, `cast_j`, `cast_k`, `cast_l`, `cast_i`, `hit`, `death` × `south`, `west`, `east`, `north`. One canonical mapping and no guessed atlas x/y. Frame `000.png` sequence consecutive, zero-padded. If a cast aliases shared `cast`, aliases must be in manifest, never inferred. Character standing at `(64,108)` feet; local hero node pivot `(0,0)` at feet through sprite offset `(-64,-108)` when `centered=false`, or equivalent explicit offset when centered.

## Event flow / decoupling
Gameplay emits: `moved(direction, speed)`, `basic_attack_started(cast_id,direction)`, `skill_cast_started(skill_id,cast_id,aim)`, `skill_active_window(skill_id,cast_id)`, `skill_cast_finished(...)`, `damage_taken`, `died`; VisualController maps to animation/state and spawns VFX. **Visual events cannot register damage, statuses, hitboxes, cooldowns, extra projectiles.** VFX reflect authoritative gameplay geometry after Augments.

## Frame validation gates
- PNG RGBA PNG dimensions exactly 128×128; alpha transparent outside silhouette; no leftover storyboard or letters; alpha bounding box allowed not touching frame edge by default unless weapon extends and is declared `allow_edge_touch`.
- Every required animation/direction exists; minimum frames per contract or explicit alias; contiguous numbering, no duplicate names; frame alpha bbox and occupied pixel changes tracked.
- Foot anchor alignment: test standing ground projection; variation max 2 pixels on idle and hit; run permitted vertical bob up to 3px while ground shadow fixed.
- Character body extent and color drift across frames: generate warnings for occupied bbox change >20% or unexpected hue/identity shifts; manual/vision screenshot check remains necessary.
- NO scaling each individual frame to fill canvas. Enforce same animation world height baseline, not every head top identical.
- Import nearest filter, no 2D texture blur, no margin/extrusion without matching generated atlas metadata; preserve lossless alpha.

## Godot implementation
- `CharacterVisual.tscn`: `VisualRoot` Node2D, `Shadow` Sprite2D, `Body` AnimatedSprite2D, `WeaponPivot` Node2D / `Weapon` Sprite2D, `FrontVFX` Node2D, `AnimationPlayer`, `VisualController` script.
- `VisualProfile.tres` resource maps `(state, facing) → animation`, duration, direction-dependent weapon sockets and draw order. Runtime reads resource; do not `match character_id` for core animation dispatch.
- Generator (Godot EditorScript or `--headless --editor --script`) reads manifest and outputs `SpriteFrames` (`.tres`) deterministically; provide stable ordering of frames, speed, loop flags, proper resource paths.
- Validate visual scene by instantiating each character, playing all four directions, transitioning run→attack→idle, and taking screenshots. Avoid Godot editor-only effects that fail in headless export.

## Failure response
An invalid frame/manifest is a **hard pipeline failure**. Do not silently replace with random frame, crop neighbor art, silently interpolate frames, use poster cutouts or scale up low-res screenshots. Show exact character, animation, direction, filename, validation error. Script should be idempotent: same source+manifest+seed→identical output files.
