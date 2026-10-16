# 06 — AUTONOMOUS AGENT EXECUTION, TOOLING, TESTING

## Autonomous production recipe
**Discover → Build → Validate → Import → Simulate → Capture → Diagnose → Repair → Report.** No manual pixel-edit actions should be assigned to the owner. Agent can use Python/Pillow + pixel geometry, command-line Pixelorama where available, Godot headless, legitimate free CC0 asset downloads if browsing/network tooling is available. If network unavailable, proceed with generated placeholder assets and disclose coverage honestly.

## Required CLI tools / dependencies
- Godot 4.x stable, GDScript, project import/export tools; Python 3.10+ with Pillow, pytest (all free).
- Pixelorama and/or Krita optional for editable animation source. If AI Agent cannot drive GUI tools, create procedural source PNGs using Python and document generation; do not claim `.pxo` was created.
- Record actual tool versions; pin dependencies in `requirements-art.txt` or equivalent. No paid package, paid API, asset scraper of copyrighted content, or cloud subscription required.

## Batch stages
```
python tools/art_pipeline/generate_hero_assets.py --character astra --seed 1
python tools/art_pipeline/validate_frames.py assets/characters/astra/manifest.json
python tools/art_pipeline/render_contact_sheet.py --character astra
# Godot: import/editor script, then headless tests (adapt command to installed version)
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/art/test_character_assets.gd
godot --headless --path . --script res://tests/art/test_map_seeds.gd
```
Tool file names describe deliverables, not preexisting executables: Agent must implement them and report correct working commands.

## Folder structure
```
art_source/{astra,vex,boros,tilesets,vfx}/
assets/characters/<id>/frames/<clip>/<direction>/<###>.png
assets/characters/<id>/manifest.json
assets/vfx/<category>/<effect>/...png
assets/tilesets/<theme>/{tiles.png,tileset.tres,manifest.json}
scenes/visual/{CharacterVisual.tscn,VFXFactory.tscn,...}
scripts/visual/{VisualController.gd,VFXFactory.gd,MapArtGenerator.gd,...}
tools/art_pipeline/{generate_hero_assets.py,validate_frames.py,...}
tests/art/{test_character_assets.gd,test_vfx_events.gd,test_map_seeds.gd,...}
screenshots/art_qa/<build_id>/...
docs/{ART_ASSET_LEDGER.csv,ART_QA_REPORT.md,ART_CHANGELOG.md}
```

## Required fully automated validators
1. JSON schema / required assets / manifest values / duplicate stable IDs / path safety.
2. RGBA & expected canvas, transparent margin, no blank frames, coherent feet anchors; invalid direction, FPS<=0, noncontinuous frame sequences rejected.
3. Godot resource load smoke tests for all SpriteFrames, scenes, shaders, TileSets; launch test world with each character.
4. Event tests for every basic + J/K/L/I: one visual source event, allowed multiple spawned visuals, no extra damage, proper despawn.
5. Time travel test: pause/resume; Auto/Manual; upgrade screen pauses visual simulation; death clears temporary VFX.
6. Augment visual tests: projectile split multiplies VFX only for spawned actual projectiles; Boros slam cannot split; beam not projectile; AOEs track new radius; echo cast doesn't create spurious hits.
7. Performance harness: 100/200/400 enemies in a test scene, stress shots; record FPS percentile, sprite count, dropped cosmetic instances, allocations, memory, Godot warnings.
8. Map generator seed repeatability + reachability, spawn clear zones, no invisible obstacle.
9. Image-diff/contact-sheet report (baseline if available). Strict pixel-perfect screenshot diff can flag false positives for non-deterministic particles; use deterministic visual seed and tolerances or per-effect masks.

## Minimum screenshots / videos
- Three full-body in-game idle screenshots, each in all 4 facings on same neutral scene.
- Three 4-way animation contact sheets, at least one short run/basic preview each.
- Fifteen action screenshots (3 chars × basic/J/K/L/I) with both neutral and environmental map as capacity permits.
- 3 map overview screenshots per template; video or GIF of map transition and heavy VFX stress scene.
- A side-by-side comparison `concept_reference` versus actual pixel-scale prototype; label scope and discrepancies.

## Failure handling
- Every failed command should be in report: exact command, exit code, log excerpt, fix, retest outcome.
- Error cannot be resolved? Mark task blocked with minimum reproducible scene and screenshot, do not mark milestone complete.
- Don't silently overwrite previous hand-designed sprites. Source versioned, generated outputs rebuildable, preserve backups and commit boundaries. Build must work from fresh checkout without absolute `D:\...` paths.
- Subjective art acceptance cannot be proven by automated tests. Deliver images to owner for review; owner may reject while technical suite passes.

## QA report template
```
Build commit/hash: ...
Godot/Python versions: ...
Completed assets: ...
Automated: pass/fail/skipped (reason)
Screenshots/contact sheets: ...
Known mismatch vs concepts: ...
FPS 95p test setting: ...
License ledger complete: yes/no
Human review requested: exact screenshots / run steps
```
