# Reproducible art pipeline

Original scripted **prototype pixel art**, not final concept-quality art. No concept image pixels are read by a generator. Tools are local Python 3.12 + Pillow 12.3 and Godot 4.7.2. No paid tools, asset downloads or runtime network services.

Run `tools/art.ps1 -Capture -Regression` in PowerShell 7. The default Python path is the installed runtime on this machine; the script accepts `-PythonPath` for another checkout. All generation/import/verification is automated. `tools/art_pipeline/finalize_report.py` builds the review gallery/GIFs after captures. No manual image editing/import is required.

Source files: `tools/art_pipeline/generate.py` (body/weapon), `generate_environment.py` (tiles/VFX manifests/provenance). Separate RGBA frames are under `assets/characters/<id>/frames/<clip>/<direction>`. Each character manifest uses the supplied handoff schema. The importer builds SpriteFrames with **full PNG textures**, avoiding atlas-neighbour bleeding. Frames use nearest sampling, four authored cardinal views, explicit animation clips, feet anchor (64,108) and presentation-only 72px normalization.

`schema_check.py` supports exactly the supplied schema keywords; unsupported keywords explicitly fail. It is not advertised as a general JSON Schema implementation. `validate.py` adds path/sequence, PNG dimensions/alpha/palette and required clip checks. `test_pipeline.py` uses stdlib unittest and deliberately invalid inputs; jsonschema/pytest are not installed.

`CharacterVisual` uses the common `VisualController`/`VisualProfile`, separate weapon pivot, shadow, front VFX and AnimationPlayer. `ActorSprite` remains the legacy adapter for quarantined source fixtures. Active loadouts use `art_frames`; legacy user-supplied atlases are no longer referenced by active loadouts. Old originals remain unchanged. Windows/Web export exclusions remove legacy sprites, legacy frame resources and the handoff/reference pack.

`CombatVisualFactory` loads fifteen VFX manifests. Real projectile nodes get one cosmetic child (maximum120); cast/hit/radial geometry drives bounded impacts (maximum80). No cosmetic RNG is consumed from RunRng. The factory is a sibling of CombatService, so effects do not consume the combat projectile budget. Shield/buff aura reads current actor state, including expiry. Pause follows scene-tree pause. Existing gameplay telegraphs remain authoritative.

`PixelTerrain` uses TileMapLayer with32px atlas tiles and **zero tile physics layers**. ArenaGeometry retains all obstacle/boundary/hazard collision ownership; raised caps and seams are drawn inside the same obstacle rectangles. Cosmetic variants use integer cell coordinates without RNG draws. The existing generator retains safe250 spawn,550 exclusion and escape corridors. `test_art_maps.gd` verifies100 seeds/theme, navigation connectivity, safe zone and collision alignment.

Open CHARACTER → **Xem đồ họa / Art preview** for real-executor controls. Preview unlock/rank/health changes are isolated fixtures, never saved or applied to production content. PLAY starts the ordinary run. `capture_preview.gd` automatically captures15 actions,24 run frames and9 map views; `stress.gd` explicitly creates100/200/400 enemies plus300 projectiles without changing production cap110.

Current intentional limits: procedural prototype pose/detail quality; four cardinal directions (diagonals choose dominant axis); frame-based low-resolution artwork at the existing viewport scale; enemies/loot/bosses retain existing readable placeholders; optional Web export depends on an installed Web export template. Owner visual approval is always separate from automated correctness.
