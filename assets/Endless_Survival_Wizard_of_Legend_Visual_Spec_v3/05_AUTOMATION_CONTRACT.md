# 05 — AGENT AUTOMATION CONTRACT / ASSET DATA / CLI

## Primary architecture
Agent is accountable for full production automation; human does not hand model, draw frames, pack atlases or click the Godot import UI. Implement scripts and reproducible input manifests; record the precise commands run and their exit codes. Treat proprietary image-generation services as optional, not required/free. Manual artistic approval is explicit only at gates.

## Repo layout (adapt to existing project instead of replacing)
```
art_source/characters/{astra,vex,boros}/
art_source/tilesets/{forest_ruins,arcane_courtyard,volcanic_remains}/
art_generated/characters/<id>/<animation>/<direction>/000.png
art_generated/vfx/<effect_id>/000.png
art_generated/maps/<biome>/
config/visual_profiles/*.json
config/visual_manifest.schema.json
scripts/art/{validate_assets.py,build_visual_assets.py,pack_atlas.py,make_contact_sheet.py}
scripts/godot/{import_visuals.gd,smoke_test.gd}
scenes/visual/{characters,vfx,maps}/
reports/visual_qa/<run_id>/{checks.json,contact_sheets,screenshots,videos,performance.csv}
licenses/asset_ledger.csv
```

## Manifest schema (see sample JSON in config)
Keys: `asset_id`, `kind`, `source_method` (pixelorama/art_layers/procedural/blender_optional/licensed_pack), `source_files`, `source_license`, `frame_canvas_px`, `opaque_height_reference_px`, `feet_anchor_px`, `directions`, `animations[name]` `{fps,loop,frames}`, `palette`, `godot_scene`, `expected_events`, `build_hash`. Store effect definitions in separate JSON keyed by stable gameplay effect ID. Reject missing, duplicate or illegal paths. All built assets have reproducible metadata; no binary-only hidden dependencies.

## Automatic production stages
`discover project → license check → create/edit source → export PNG RGBA → anchor/palette/alpha tests → human-readable contacts → optional atlas → headless Godot import → runtime smoke tests → video/screenshots → visual QA → user signoff`. Any failure emits a report and stops the gate. Each stage should be resumable/idempotent with stable hash of inputs+configuration.

## Cross-platform commands — illustrative only
```
python scripts/art/validate_assets.py --manifest config/visual_profiles/astra.json
python scripts/art/build_visual_assets.py --character astra --all
# Optional Blender props only (not default for characters):
blender -b art_source/props/column.blend --python scripts/art/blender_render_prop.py
# Use discovered Godot binary/path and validated flags for installed version:
godot --headless --path <actual_repo> --editor --quit
# Then run the repository's actual smoke-test script on verified Godot CLI.
```
These are *contracts/examples*, not a claim the exact commands have run. Path settings and Godot binaries must be detected and logged. Do not assume `pixelorama` CLI flags before verifying executable/version.

## Validation requirements
- PNG decode, RGBA, transparency where required; every frame equal canvas size; valid feet anchor; frame count matches manifest; no wholly blank essential frames; no cropped sword/muzzle; same visual height profile; color occupancy/palette outliers; atomic writes.
- Contact sheet per character/direction/state; no unattended 'perfect aesthetic match' claim. Use comparisons at 1× viewport.
- Fully deterministic registry → import `.tres`/`.tscn` resource generation; preserve existing references, side-by-side versioned scenes until validated.
- Resource provenance: URL, author, license, license snapshot/date, modifications. If source license is ambiguous, don't use. Verify tool/code license separately.

## Modularity test
A brand new character with `visual_profile` and compatible skill shapes must reuse sprite importer, `VisualController`, VFX factory, collision-geometry bindings and atlas packer without editing character-name branches. Unit test three existing characters. Gameplay tests remain unchanged and must pass.
