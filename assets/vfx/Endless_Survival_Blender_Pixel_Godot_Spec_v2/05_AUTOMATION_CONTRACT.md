# 05 — AUTOMATED ASSET PRODUCTION CONTRACT
## 1. Repository layout
```text
config/visual_pipeline.json
config/character_visual_manifest.schema.json
assets/source_3d/astra/master.blend
assets/source_3d/vex/master.blend
assets/source_3d/boros/master.blend
assets/source_3d/worlds/{temple,forest,volcanic}/*.blend
assets/generated/characters/<id>/<animation>/<direction>/<frame>.png
assets/generated/vfx/<primitive>/*.png
assets/generated/tiles/<biome>/*.png
scenes/visual/characters/<id>_visual.tscn
scenes/visual/vfx/<primitive>.tscn
scenes/maps/<biome>.tscn
tools/visual_pipeline/{generate_models,rig,animate,render,quantize,validate,import_godot,capture,report}.*
reports/visual_qa/<timestamp>/{manifest,metrics,contact_sheets,clips,logs}/*
licenses/asset_ledger.csv
```

## 2. Agent command-line contracts
All commands support `--config`, `--character` or `--biome`, `--seed`, `--output`, nonzero exit on error, reproducible logs, `--dry-run` where safe. No dependency on GUI clicks for normal workflow. Pin environment in `requirements-visual.txt` and `versions.lock`.

`01_model`: build Blender master scene or import vetted licensed input; assert collections/meshes/weapon sockets. `02_rig`: add armature, normalize unit scale, bind geometry and output bone audit. `03_animate`: create/list named actions and markers; check lengths. `04_render`: Blender `-b` renders all requested camera/view/action frame PNGs, separate optional shadow pass. `05_pixelize`: resize nearest to exact target *after anti-aliased supersample source*, palette tune with fixed LUT/dithering optional, alpha cleanup without shrinking silhouette or moving feet. `06_validate`: inspect RGBA frame dims, anchor, content bbox, empty/duplicate suspicious frames, adjacency bleed, palette stats. `07_import`: Godot `@tool` / `EditorScript` builds `SpriteFrames` resources, AnimatedSprite2D scenes and material hookups based on manifest. `08_capture`: launch debug scene with controlled seeds and automated camera to export frames/clips; record manual checklist. `09_report`: summarize test and licensing status.

**Important:** `blender --background --python pipeline.py -- --config path...` forwards arguments after `--` to Python script. Godot CLI `--headless --path <project> --editor --quit` imports resources; `--headless --path <project> --script res://tools/...gd` for custom script with project-ready validation (exact command flags tested on installed version). Do not assume running editor import and tests concurrently on same project is safe.

## 3. Blender camera and render invariants
One pinned world unit scale, camera target at origin/feet, orthographic scale, camera elevation and azimuth, world illumination rig, color transform (e.g. Standard, not inconsistent AgX/Filmic per character) and transparency settings. Use Eevee workbench/stylized materials depending on renderer available, write 16-bit/8-bit RGBA only as required. Stage renders to temp and atomic rename to final directory after full validation. Render sample sprite first, compare camera lock against approved template.

## 4. Image pipeline invariants
- Process all frames of an animation as one **batch**, determine stable alpha bbox over union of frames, preserve shared feet anchor. Avoid auto-trimming per frame.
- If converting to pixel art, consistently quantize colors using same character palette fitted on sampled *all poses*, not a new palette per frame (causes flicker).
- Never create new alpha pixels across transparent boundaries in quantization. Test halo against black/white/midgray compositions. Maintain premultiplication assumptions in import.
- Atlas packing optional; preferred demo source = separate frame PNGs. If packing atlas, store explicit rect for every image and >1px extruded padding (unless sprite atlas/crop behavior makes extrusion inappropriate) to avoid sampling bleed. No assumption that an image is regular evenly spaced grid without validated metadata.

## 5. Resource-oriented Godot import
- Manifest loader validates against JSON schema in Python stage. Godot importer creates animations with FPS/loop flags, sets texture filtering/pivot and visibility; recognizes event markers from animation table. Store `VisualDefinition` Resource referencing sprites/VFX and socket offsets. Godot combat modules reference `VisualDefinition`, **never** generated PNG file names directly in character-specific gameplay code.
- Each exported asset has provenance `source_art`, Blender source hash, generator version, render settings hash, palette version, license. Generated art may be regenerated without changing manifest keys.

## 6. Failure handling and audit
If character fails consistency validation, keep previous working revision; output failure report with screenshot. If source `.blend` missing, do NOT hallucinate that it has been generated; use scripted primitive silhouette as placeholder with `status: placeholder` and record blocker. If free external service fails, continue with offline fallback and annotate quality gap. Never claim image semantic accuracy or 'concept fidelity' merely from pixel statistics.

## 7. Agent report schema
Must include branch/commit; Blender/Godot versions; what was generated vs reused; sources/licenses; files changed; build/tests exact command + exit codes; screenshots and clips; known differences from concept; visual-review requested; evidence location; next tasks. User should only need to inspect and approve/reject, no asset production steps.
